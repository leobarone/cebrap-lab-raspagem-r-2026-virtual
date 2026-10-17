---
title: "Tutorial 5 — Da API da Câmara ao corpus: coletando PDFs de proposições legislativas"
lang: pt-BR
output:
  html_document:
    toc: true
    toc_depth: 2
    number_sections: false
---

```{r configuracao, include=FALSE}
knitr::opts_chunk$set(echo = TRUE, message = FALSE)
```

# Apresentação do problema

Nos primeiros tutoriais, aprendemos a capturar uma tabela da Wikipedia, examinar a estrutura de documentos HTML e utilizar *for loops* para visitar diversas páginas e guardar seus textos. Na atividade anterior, conhecemos o formato JSON e fizemos nossas primeiras consultas à **API de Dados Abertos da Câmara dos Deputados**.

Lembra do que fizemos no final do Tutorial 4? Pedimos uma lista de Projetos de Lei (PLs) de 2025 e, usando o `id` de uma proposição, consultamos um segundo endereço da API para recuperar seus detalhes. Entre as informações obtidas, encontramos um campo particularmente interessante: `urlInteiroTeor`.

Esse campo pode nos levar ao documento que contém o texto da proposição. Ou seja, podemos ir além da **ementa**, que é uma descrição resumida do projeto, e trabalhar com o **inteiro teor** do documento.

Nosso objetivo agora será construir um **corpus de proposições legislativas**. Um *corpus* é um conjunto de textos reunidos segundo algum critério, preparado para uma análise. No nosso caso, começaremos com uma pequena coleção de PLs apresentados em 2025. Ao final, teremos uma tabela em que **cada linha corresponde a um documento**, com seu identificador, seus metadados e o texto extraído de seu PDF.

Vamos fazer isso em etapas:

1. Consultar a API para recuperar uma pequena lista de PLs de 2025.
2. Visitar o endpoint de detalhes de cada proposição e obter seu endereço de inteiro teor.
3. Baixar os documentos disponíveis em PDF.
4. Extrair os textos dos PDFs e reuni-los em um *data frame*.
5. Conferir os resultados e salvar o corpus para as próximas atividades.

**Atenção:** vamos começar com **dez proposições**, não com todos os PLs de 2025. Isso nos permitirá entender cada etapa antes de pensar em uma coleta maior. Como já vimos com os parques nacionais, primeiro precisamos fazer a operação funcionar com poucos casos; depois podemos repeti-la.

# Preparando o ambiente

Utilizaremos três pacotes principais:

- *httr2*, para consultar a API e baixar os arquivos.
- *tidyverse*, para organizar os dados, trabalhar com textos e construir nossas tabelas.
- *pdftools*, para ler o conteúdo dos PDFs.

O pacote *jsonlite*, que conhecemos no Tutorial 4, também é utilizado na interpretação do JSON, mas não precisaremos chamá-lo diretamente nesta atividade: `resp_body_json()`, do *httr2*, já faz essa conversão.

Se os pacotes não estiverem instalados, execute os comandos abaixo **uma vez** no seu computador:

```{r instalar-pacotes, eval=FALSE}
install.packages("httr2")
install.packages("tidyverse")
install.packages("pdftools")
```

Agora vamos carregá-los para nossa sessão de trabalho:

```{r carregar-pacotes}
library(httr2)
library(tidyverse)
library(pdftools)
```

**Obs.:** não é necessário carregar `stringr` ou `dplyr` separadamente, pois eles fazem parte do *tidyverse*. Também não precisamos instalar o *tidytext* ainda: nesta aula vamos **construir** o corpus; a preparação das palavras e as análises textuais ficam para uma etapa posterior.

## Em que pasta os arquivos serão guardados?

Diferentemente do tutorial dos parques, no qual guardamos diretamente os textos em uma tabela, agora também queremos **baixar arquivos para o computador**. Vamos, portanto, criar duas pastas:

- `inteiro_teor`: guardará os PDFs baixados.
- `data`: guardará as tabelas que produziremos em formato CSV.

```{r criar-diretorios}
dir.create("inteiro_teor", showWarnings = FALSE)
dir.create("data", showWarnings = FALSE)

getwd()
```

A função `dir.create()` cria uma pasta. O argumento `showWarnings = FALSE` evita um aviso caso a pasta já exista.

`getwd()` mostra nossa pasta de trabalho. É dentro dela que os novos diretórios serão criados. Se você estiver usando um projeto do RStudio, prefira executar o tutorial com esse projeto aberto, para não espalhar os arquivos por pastas diferentes.

# Retomando a API da Câmara: uma lista de PLs

Vamos recuperar a operação que já aprendemos no Tutorial 4. A documentação da API está disponível [neste endereço](https://dadosabertos.camara.leg.br/swagger/api.html?tab=api). Nosso primeiro endpoint será:

```text
https://dadosabertos.camara.leg.br/api/v2/proposicoes
```

Queremos os Projetos de Lei de 2025, ordenados por `id`, e vamos pedir dez registros. Para isso, construiremos uma requisição com `request()`, acrescentaremos o cabeçalho e os filtros e, finalmente, executaremos a consulta com `req_perform()`.

```{r consultar-lista-de-pls}
url_proposicoes <- "https://dadosabertos.camara.leg.br/api/v2/proposicoes"

req <- request(url_proposicoes) %>%
  req_headers(Accept = "application/json") %>%
  req_url_query(
    siglaTipo = "PL",
    ano = 2025,
    ordem = "ASC",
    ordenarPor = "id",
    itens = 10
  )

resp <- req_perform(req)

corpo <- resp_body_json(resp, simplifyVector = TRUE)

df_proposicoes_simples <- as_tibble(corpo$dados)
```

Avance devagar. Neste trecho não utilizamos nenhuma função nova: já fizemos todas essas operações na aula anterior.

`req` contém a requisição preparada. `resp` contém a resposta recebida do servidor. `resp_body_json()` interpreta o JSON, e `corpo$dados` recupera a parte da resposta que contém as proposições. Por fim, `as_tibble()` guarda os registros em nosso formato habitual de tabela.

Vamos examinar o resultado:

```{r conferir-lista-de-pls}
nrow(df_proposicoes_simples)

names(df_proposicoes_simples)

df_proposicoes_simples %>%
  select(id, siglaTipo, numero, ano, ementa) %>%
  head()
```

É importante não confundir os campos `numero` e `id`. Um projeto é conhecido publicamente por algo como **PL número X/2025**. Mas a API também atribui a ele um **identificador próprio**, guardado em `id`. É esse identificador que utilizaremos na próxima consulta.

Também vale lembrar que `itens = 10` pede **dez registros de uma página**, não todos os PLs de 2025. A API permite até 100 registros por página. Para reunir um universo maior, seria necessário percorrer as páginas de resultados, utilizando o parâmetro `pagina`, como já discutimos no Tutorial 4. Por enquanto, ficaremos com nosso pequeno conjunto.

## Preparando os identificadores

No tutorial dos parques nacionais, usamos `pull()` para extrair uma coluna de endereços e obter um vetor. Aqui faremos exatamente a mesma coisa com os identificadores:

```{r extrair-ids}
ids_proposicoes <- df_proposicoes_simples %>%
  pull(id)

ids_proposicoes
length(ids_proposicoes)
```

O resultado é um vetor numérico. Cada elemento identifica uma proposição.

Mais adiante vamos percorrer esse vetor com um `for loop`, assim como percorremos o vetor `url_parques` na atividade anterior. Mas primeiro vamos consultar **uma única proposição**.

# Obtendo os detalhes de uma proposição

Vamos selecionar o primeiro identificador:

```{r escolher-um-id}
id_proposicao <- ids_proposicoes[1]

id_proposicao
```

Lembre-se do endpoint que consultamos na atividade anterior: `/proposicoes/{id}`. Precisamos substituir `{id}` pelo identificador escolhido.

```{r montar-endereco-detalhe}
url_detalhe <- paste0(url_proposicoes, "/", id_proposicao)

url_detalhe
```

A função `paste0()` junta os pedaços do endereço. O resultado é a URL de uma proposição específica, e não mais a URL da lista de projetos.

Agora podemos fazer a consulta:

```{r consultar-um-detalhe}
req_detalhe <- request(url_detalhe) %>%
  req_headers(Accept = "application/json")

resp_detalhe <- req_perform(req_detalhe)

proposicao <- resp_body_json(resp_detalhe, simplifyVector = TRUE)$dados

names(proposicao)
```

Observe que utilizamos as mesmas funções de antes. A diferença está no **endereço consultado** e na **estrutura do resultado**. Na listagem, o elemento `dados` continha várias proposições. Agora, ele contém os detalhes de **uma única proposição**.

Vamos recuperar algumas de suas informações:

```{r examinar-campos-detalhe}
proposicao$id
proposicao$numero
proposicao$ano
proposicao$ementa
proposicao$urlInteiroTeor
```

O campo `urlInteiroTeor` é especialmente importante. Ele pode conter o endereço do documento da proposição. Mas ainda não é o documento: **é apenas o endereço que permite tentar obtê-lo**.

Observe também que a resposta traz outras informações, inclusive estruturas dentro de estruturas, como `statusProposicao`. Assim como vimos no tutorial de JSON, não precisamos transformar tudo em colunas de uma só vez. Podemos escolher as informações relevantes para o objetivo da nossa pesquisa.

# Criando nossa primeira função

Agora sabemos como consultar os detalhes de **um** PL. Nosso próximo desafio será repetir esse procedimento para todos os identificadores de `ids_proposicoes`.

Poderíamos copiar o código anterior para cada projeto, substituindo manualmente o `id`. Mas isso seria trabalhoso. Já aprendemos que, quando uma tarefa precisa ser repetida, podemos utilizar um *for loop*.

Antes disso, vamos conhecer outra ferramenta importante: uma **função criada por nós**.

Uma função reúne instruções que realizam determinada tarefa. Em vez de escrever essas instruções toda vez, podemos dar um nome à função e executá-la com valores diferentes.

## Uma função bem pequena

Veja o exemplo:

```{r primeira-funcao}
multiplicar_por_7 <- function(numero) {
  resultado <- numero * 7
  resultado
}

multiplicar_por_7(3)
multiplicar_por_7(5)
```

Podemos ler a primeira linha assim: estamos criando uma função chamada `multiplicar_por_7`, que recebe um valor chamado `numero`.

As instruções entre as chaves dizem o que deve ser feito com esse valor. Quando chamamos `multiplicar_por_7(3)`, o R coloca o número 3 no lugar de `numero`, executa as instruções e devolve o resultado.

O nome `numero` foi escolhido por nós. Poderíamos ter utilizado outro. No R, o resultado da **última expressão** de uma função é devolvido automaticamente. Por isso, na última linha, escrevemos apenas `resultado`.

Uma função e um loop não são a mesma coisa. **A função define uma tarefa; o loop permite executá-la repetidamente.** Vamos combinar as duas ferramentas.

## A função que consulta uma proposição

Nossa nova função receberá um `id`, montará a URL, consultará a API e devolverá um *tibble* com **uma linha**.

Vamos guardar apenas algumas informações úteis para o corpus. Não precisamos, nesta atividade, das muitas variáveis sobre a tramitação que aparecem no JSON.

```{r definir-funcao-detalhe}
obter_proposicao_detalhe <- function(id) {

  url_detalhe <- paste0(url_proposicoes, "/", id)

  req <- request(url_detalhe) %>%
    req_headers(Accept = "application/json")

  resp <- req_perform(req)

  proposicao <- resp_body_json(resp, simplifyVector = TRUE)$dados

  url_pdf <- proposicao$urlInteiroTeor
  if (is.null(url_pdf)) url_pdf <- NA_character_

  tibble(
    id = proposicao$id,
    siglaTipo = proposicao$siglaTipo,
    numero = proposicao$numero,
    ano = proposicao$ano,
    dataApresentacao = proposicao$dataApresentacao,
    ementa = proposicao$ementa,
    urlInteiroTeor = url_pdf
  )
}
```

Parece mais código do que na nossa primeira função, mas observe que **quase todas as linhas já apareceram na atividade anterior**. A novidade é que reunimos essas operações entre as chaves de `function(id)`.

Vamos traduzir as partes principais:

1. Recebemos o identificador de uma proposição no argumento `id`.
2. Construímos o endereço do endpoint com `paste0()`.
3. Preparamos e executamos a consulta à API.
4. Extraímos os dados do JSON recebido.
5. Criamos um `tibble()` com uma linha contendo as variáveis que queremos guardar.

Há apenas um cuidado adicional. Algumas proposições podem não ter um endereço em `urlInteiroTeor`. Nesse caso, o valor pode aparecer como `NULL` em R. Usamos então:

```{r explicar-ausencia-de-url, eval=FALSE}
url_pdf <- proposicao$urlInteiroTeor
if (is.null(url_pdf)) url_pdf <- NA_character_
```

A instrução `if` significa **se**: se não encontramos um valor, guardamos `NA_character_`, que representa uma informação textual ausente. Assim podemos manter uma linha no nosso *data frame* mesmo quando não há endereço disponível.

Agora vamos testar nossa função usando o mesmo identificador de antes:

```{r testar-funcao-detalhe}
obter_proposicao_detalhe(id_proposicao)
```

Pronto! Nossa função já consegue obter os metadados de uma proposição. A diferença é que, agora, podemos chamá-la para qualquer outro `id`.

# Repetindo a consulta para vários projetos

Vamos recuperar a lógica do Tutorial 3. Naquela atividade, utilizamos um `for loop` para percorrer os endereços dos parques. A cada passagem, capturamos uma página e acrescentamos uma linha ao *data frame* com `bind_rows()`.

Aqui faremos quase a mesma coisa. Mas, em vez de visitar uma URL já pronta, **chamaremos a função `obter_proposicao_detalhe()` para cada identificador**.

## Uma maneira de lidar com falhas

Como dependemos de um serviço externo, uma consulta pode falhar. Por exemplo, o servidor pode estar temporariamente indisponível. Uma função do pacote *purrr*, que já faz parte do *tidyverse*, pode ajudar:

```{r criar-funcao-segura}
obter_detalhe_seguro <- purrr::possibly(
  obter_proposicao_detalhe,
  otherwise = NULL
)
```

`possibly()` cria outra versão da nossa função. Se a consulta funcionar, teremos o *tibble* normalmente. Se ocorrer um erro, a nova função devolverá `NULL` em vez de interromper toda a repetição.

Isso é útil, mas exige cuidado: **uma coleta que não parou não é necessariamente uma coleta completa**. Por isso vamos conferir, depois, quais identificadores foram realmente obtidos. Se algum projeto ficou de fora, será necessário investigar e, eventualmente, executar novamente a consulta que falhou.

## O loop de detalhes

Vamos começar com um objeto vazio, como fizemos com os textos dos parques:

```{r iniciar-tabela-detalhes}
df_proposicoes <- NULL
```

Agora podemos percorrer nosso vetor:

```{r coletar-detalhes}
for (id in ids_proposicoes) {

  print(id)
  Sys.sleep(1)

  linha_proposicao <- obter_detalhe_seguro(id)

  df_proposicoes <- bind_rows(df_proposicoes, linha_proposicao)

}
```

Leia o código devagar. Para cada `id`, o R aguarda um segundo, consulta os detalhes e tenta construir uma linha. Em seguida, `bind_rows()` acrescenta a nova linha ao que já estava guardado em `df_proposicoes`.

Não estamos pedindo um número enorme de consultas: temos apenas dez identificadores. A pausa evita fazer solicitações em sequência muito rápida, mas não substitui o respeito às condições de uso da API.

Vamos examinar o que obtivemos:

```{r conferir-detalhes}
stopifnot(nrow(df_proposicoes) > 0)

nrow(df_proposicoes)

glimpse(df_proposicoes)

df_proposicoes %>%
  select(id, numero, ano, urlInteiroTeor) %>%
  head()
```

O resultado é um data frame em que **cada linha representa uma proposição**. Agora temos mais informações do que na primeira consulta, inclusive o endereço de inteiro teor.

E se alguma consulta falhou? Podemos comparar os identificadores que pedimos com aqueles que conseguimos recuperar:

```{r conferir-ids-obtidos}
ids_obtidos <- df_proposicoes %>%
  pull(id)

ids_sem_detalhe <- setdiff(ids_proposicoes, ids_obtidos)

ids_sem_detalhe
```

`setdiff()` encontra os valores que aparecem no primeiro vetor, mas não no segundo. Se o resultado estiver vazio, conseguimos os detalhes de todos os projetos escolhidos. Se houver algum `id`, significa que essa proposição não entrou no nosso data frame.

**Exercício:** por que não seria correto dizer que coletamos dez proposições apenas porque `length(ids_proposicoes)` é igual a dez? Qual é a diferença entre **pedir** dez registros e **obter com sucesso** os detalhes de dez registros?

# Preparando os endereços de inteiro teor

Já temos os metadados. Agora vamos selecionar as proposições que possuem um endereço de inteiro teor disponível.

```{r filtrar-urls-de-documentos}
df_com_url <- df_proposicoes %>%
  filter(!is.na(urlInteiroTeor), nzchar(urlInteiroTeor))

nrow(df_com_url)

df_com_url %>%
  select(id, numero, urlInteiroTeor) %>%
  head()
```

`is.na()` identifica valores ausentes. O símbolo `!` significa **não**. Já `nzchar()` verifica se um texto contém pelo menos um caractere. Assim, mantemos apenas as linhas em que há um endereço não vazio.

**Obs.:** ter um endereço de inteiro teor não significa, por si só, que já possuímos um arquivo PDF. Ainda precisamos visitar o endereço e examinar o que o servidor nos devolveu.

# Baixando nosso primeiro PDF

Vamos começar por apenas uma proposição, como fizemos com a captura do texto de um parque.

Selecionaremos o primeiro identificador e o primeiro endereço da tabela filtrada:

```{r escolher-documento-de-teste}
stopifnot(nrow(df_com_url) > 0)

id_pdf <- df_com_url %>%
  pull(id) %>%
  head(1)

url_pdf <- df_com_url %>%
  pull(urlInteiroTeor) %>%
  head(1)

id_pdf
url_pdf
```

`pull()` devolve um vetor, e `head(1)` conserva apenas seu primeiro elemento. Como recuperamos os dois valores da **mesma tabela e na mesma ordem**, o endereço e o identificador correspondem à mesma proposição.

Vamos fazer uma requisição para esse endereço:

```{r solicitar-primeiro-pdf}
req_pdf <- request(url_pdf)

resp_pdf <- req_perform(req_pdf)

resp_status(resp_pdf)
resp_header(resp_pdf, "content-type")
```

Até aqui, `httr2` continua fazendo o mesmo trabalho: preparar e executar uma requisição. Mas agora esperamos receber o **conteúdo de um arquivo**, e não um documento JSON.

A função `resp_header()` permite examinar uma informação do cabeçalho da resposta. O campo `content-type` descreve o tipo de conteúdo informado pelo servidor. Para um PDF, podemos encontrar `application/pdf`. Alguns servidores, entretanto, utilizam nomes de tipo mais genéricos.

## Quando a resposta não é um JSON

No Tutorial 4, utilizamos `resp_body_json()` para interpretar o corpo da resposta. Agora isso não faria sentido: um arquivo PDF não está escrito em JSON.

Vamos utilizar `resp_body_raw()`, que devolve o conteúdo da resposta como uma sequência de **bytes**, isto é, os dados do arquivo em sua forma original:

```{r examinar-bytes-do-pdf}
conteudo_pdf <- resp_body_raw(resp_pdf)

length(conteudo_pdf)
```

O resultado de `length()` indica quantos bytes foram recebidos. Não precisamos ler esses bytes como se fossem palavras: trata-se do conteúdo de um arquivo.

Antes de guardá-lo com a extensão `.pdf`, vamos conferir uma característica simples dos arquivos desse formato. Em geral, um PDF começa com a sequência `%PDF`. Podemos examinar os quatro primeiros bytes:

```{r verificar-assinatura-pdf}
stopifnot(length(conteudo_pdf) >= 4)

rawToChar(conteudo_pdf[1:4])
```

Se o resultado for `%PDF`, temos um bom indício de que recebemos um PDF. Essa pequena conferência é importante porque **dar a um arquivo o nome `123.pdf` não o transforma em PDF**. Por exemplo, uma página de erro em HTML pode ser salva por engano com esse nome se não examinarmos o que recebemos.

Vamos guardar o arquivo **apenas se** o conteúdo começar com `%PDF`:

```{r salvar-primeiro-pdf}
destino_pdf <- file.path("inteiro_teor", paste0(id_pdf, ".pdf"))

if (rawToChar(conteudo_pdf[1:4]) == "%PDF") {
  writeBin(conteudo_pdf, destino_pdf)
}

file.exists(destino_pdf)
```

Se o resultado de `file.exists()` for `FALSE`, o conteúdo não foi salvo como PDF. Isso não impede que continuemos a atividade: nosso loop tentará também os demais endereços.

`file.path()` monta um caminho para o arquivo dentro da pasta `inteiro_teor`. O nome será formado pelo **id da proposição**, seguido de `.pdf`. Isso nos permitirá relacionar o arquivo aos metadados mais adiante.

`writeBin()` grava no disco os bytes recebidos. Com `file.exists()`, verificamos se o arquivo realmente foi criado.

**Exercício:** abra a pasta `inteiro_teor` e tente visualizar o PDF em um leitor de documentos. Compare o número do identificador no nome do arquivo com o `id` que utilizamos para obter seus metadados.

# Criando uma função para baixar os documentos

Aprendemos a verificar e salvar o conteúdo de um endereço. Agora vamos transformar as mesmas instruções em uma função que receba **um identificador e um endereço** e tente salvar o arquivo.

A função devolverá `TRUE` quando conseguir baixar um PDF e `FALSE` quando não houver endereço ou o conteúdo recebido não tiver a assinatura de PDF.

```{r definir-funcao-download}
baixar_inteiro_teor <- function(id, url, pasta = "inteiro_teor") {

  if (is.na(url) || !nzchar(url)) return(FALSE)

  resp <- request(url) %>%
    req_perform()

  conteudo <- resp_body_raw(resp)

  if (length(conteudo) < 4) return(FALSE)
  if (rawToChar(conteudo[1:4]) != "%PDF") return(FALSE)

  destino <- file.path(pasta, paste0(id, ".pdf"))
  writeBin(conteudo, destino)

  TRUE
}
```

Observe que, mais uma vez, apenas reunimos em uma função operações que já aprendemos. Há duas novidades pequenas:

- `return(FALSE)` permite **encerrar a função** imediatamente, devolvendo `FALSE` quando não é possível continuar.
- Escrever apenas `TRUE` ao final indica que, se chegamos até ali, o conteúdo passou pelas verificações e foi gravado.

O argumento `pasta = "inteiro_teor"` define um **valor padrão**. Podemos chamar a função passando apenas `id` e `url`; nesse caso, ela usará nossa pasta de PDFs. Se quisermos outra pasta, poderemos informá-la como terceiro argumento.

Vamos criar uma versão que não interrompa todo o loop caso uma requisição apresente erro:

```{r criar-funcao-download-segura}
baixar_pdf_seguro <- purrr::possibly(
  baixar_inteiro_teor,
  otherwise = FALSE
)
```

Lembra de `possibly()`? Se ocorrer um erro na consulta ou na gravação, `baixar_pdf_seguro()` devolverá `FALSE`. Mais uma vez, vamos **registrar e examinar o resultado**, em vez de supor que todos os documentos foram baixados.

# Baixando os PDFs das proposições

Temos uma tabela com duas informações que precisam ser utilizadas juntas: o identificador `id` e o endereço `urlInteiroTeor`. Vamos extraí-las em dois vetores:

```{r preparar-vetores-para-download}
ids_download <- df_com_url %>%
  pull(id)

urls_download <- df_com_url %>%
  pull(urlInteiroTeor)

length(ids_download)
length(urls_download)
```

Os dois vetores têm a mesma quantidade de elementos e foram construídos a partir da mesma tabela, na mesma ordem. Por isso, `ids_download[1]` corresponde a `urls_download[1]`, e assim por diante.

No Tutorial 3, utilizamos `for (url_parque in url_parques)` porque precisávamos percorrer apenas um vetor. Agora queremos recuperar **dois valores correspondentes em cada passagem**. Uma maneira simples de fazer isso é percorrer as posições dos vetores.

A função `seq_along()` produz a sequência de posições de um vetor. Por exemplo:

```{r exemplo-seq-along}
seq_along(c("Itatiaia", "Tijuca", "Alto Cariri"))
```

O resultado é `1, 2, 3`. Podemos usar esses números para acessar, ao mesmo tempo, as posições correspondentes de nossos vetores.

Vamos criar uma tabela vazia para registrar se o download de cada documento funcionou:

```{r iniciar-controle-download}
controle_download <- NULL
```

Agora nosso loop:

```{r baixar-pdfs}
for (i in seq_along(ids_download)) {

  id_atual <- ids_download[i]
  url_atual <- urls_download[i]

  print(id_atual)
  Sys.sleep(1)

  baixou <- baixar_pdf_seguro(id_atual, url_atual)

  controle_download <- bind_rows(
    controle_download,
    tibble(id = id_atual, baixou_pdf = baixou)
  )

}
```

Vamos traduzir:

1. `i` recebe a posição do documento que estamos processando.
2. `id_atual` e `url_atual` recebem os valores encontrados nessa posição dos dois vetores.
3. Chamamos `baixar_pdf_seguro()` para tentar salvar o documento.
4. A função devolve `TRUE` ou `FALSE`.
5. Guardamos o identificador e o resultado do download em `controle_download`, acrescentando uma linha a cada passagem.

Ufa! É um pouco mais trabalhoso do que baixar um único arquivo, mas a lógica é a mesma que aprendemos na atividade dos parques: **repetir uma operação e guardar o resultado de cada repetição**.

Vamos conferir:

```{r conferir-downloads}
controle_download

controle_download %>%
  count(baixou_pdf)
```

Na tabela de controle, `TRUE` significa que a função conseguiu salvar um conteúdo identificado como PDF; `FALSE` significa que o download não foi concluído dessa maneira. Se houver falhas, você pode localizar os identificadores correspondentes e verificar o que ocorreu.

Também podemos observar os arquivos que estão na pasta:

```{r listar-arquivos-baixados}
list.files("inteiro_teor", pattern = "\\.pdf$")
```

**Obs.:** se você já executou o tutorial antes, a pasta pode conter arquivos de uma execução anterior. Por isso, para construir nosso corpus, vamos utilizar os **identificadores registrados como downloads bem-sucedidos nesta execução**, e não simplesmente todos os arquivos encontrados na pasta.

# Preparando a lista de PDFs para leitura

Queremos ler apenas os arquivos que conseguimos baixar. Vamos selecionar as linhas de `controle_download` em que `baixou_pdf` é `TRUE` e formar os nomes dos documentos.

```{r preparar-arquivos-pdf}
arquivos_pdf <- controle_download %>%
  filter(baixou_pdf) %>%
  mutate(arquivo_pdf = paste0(id, ".pdf")) %>%
  pull(arquivo_pdf)

arquivos_pdf
length(arquivos_pdf)
```

Usamos `filter()`, `mutate()` e `pull()`, funções do *dplyr* que já conhecemos. O resultado é um vetor de nomes de arquivos, como `123456.pdf`.

Vamos conferir se há pelo menos um documento disponível:

```{r verificar-arquivos-pdf}
stopifnot(length(arquivos_pdf) > 0)
```

Se não houver nenhum, devemos voltar à etapa de download. Não faz sentido continuar tentando extrair textos de arquivos que não foram obtidos.

# Lendo o texto de um PDF

Agora vem uma etapa nova e bastante interessante. Temos os documentos guardados no computador, mas queremos transformar seus textos em dados que possam ser utilizados no R.

Para isso usaremos o pacote *pdftools*. Sua função `pdf_text()` lê um arquivo PDF e tenta extrair o texto de suas páginas.

Vamos começar com o primeiro arquivo da lista:

```{r escolher-pdf-para-leitura}
arquivo_pdf <- arquivos_pdf[1]

caminho_pdf <- file.path("inteiro_teor", arquivo_pdf)

caminho_pdf
```

`file.path()` nos devolve o caminho completo **dentro de nosso projeto**. É esse caminho que passaremos à função `pdf_text()`:

```{r ler-primeiro-pdf}
paginas <- pdf_text(caminho_pdf)

class(paginas)
length(paginas)
```

Observe o resultado: `paginas` é um **vetor de textos**. Cada elemento contém o texto extraído de uma página do documento. Se o PDF tiver cinco páginas, o vetor terá cinco elementos.

Podemos observar o começo da primeira página com `substr()`, que seleciona uma parte de um texto:

```{r examinar-primeira-pagina}
substr(paginas[1], 1, 600)
```

Isso significa: mostre, no máximo, os primeiros 600 caracteres do texto da primeira página. Não precisamos imprimir um documento inteiro para verificar se a extração funcionou.

## Reunindo as páginas em um texto

No Tutorial 3, tínhamos um vetor com os parágrafos de um artigo da Wikipedia. Para guardar todo o conteúdo em uma linha de um *data frame*, reunimos os parágrafos com `paste0(..., collapse = " ")`.

Agora faremos algo muito parecido, só que com **páginas de um PDF**. Vamos utilizar `paste()` e separar as páginas por uma quebra de linha, representada por `"\n"`:

```{r reunir-paginas}
texto_pdf <- paste(paginas, collapse = "\n")

length(texto_pdf)
nchar(texto_pdf)
```

Por que usamos `collapse = "\n"`? Porque queremos manter uma pequena separação entre o final de uma página e o começo da seguinte. A quebra de linha evita que esses trechos sejam colados sem nenhum separador.

Agora temos um vetor de comprimento **um**, com o texto reunido de todas as páginas. Já `nchar(texto_pdf)` informa quantos caracteres foram extraídos.

Essa diferença entre `length()` e `nchar()` também apareceu na atividade dos parques nacionais. É importante não confundi-las: um único elemento de um vetor pode conter um texto muito longo.

## Nem todo PDF contém texto selecionável

Há um cuidado importante. Um arquivo PDF pode conter caracteres de texto, mas também pode conter apenas **imagens de páginas digitalizadas**. Nesse segundo caso, `pdf_text()` pode devolver pouco texto ou mesmo um texto vazio.

Isso não significa necessariamente que o PDF esteja vazio. Significa que o conteúdo talvez não esteja disponível como texto que o computador consegue selecionar.

Uma possibilidade é utilizar **OCR** (*Optical Character Recognition*, ou reconhecimento óptico de caracteres), que tenta reconhecer letras e palavras em imagens. O *pdftools* oferece `pdf_ocr_text()`, mas essa operação requer ferramentas adicionais, como o pacote *tesseract*, e está fora do objetivo desta primeira atividade.

Por enquanto, vamos **examinar o resultado de `pdf_text()`** e guardar essa informação. Não presumiremos que todos os documentos, apenas por terem sido apresentados em 2025, possuam texto extraível.

# Criando uma função para ler PDFs

Nossa próxima tarefa será repetir a leitura para todos os documentos de `arquivos_pdf`. Já sabemos o caminho: **primeiro criamos uma função que resolve um documento; depois utilizamos um loop para aplicá-la a vários arquivos**.

Queremos produzir, para cada PDF, uma tabela com quatro informações:

| Coluna | O que representa |
|:---|:---|
| `id` | Identificador da proposição, recuperado do nome do arquivo. |
| `n_paginas` | Número de páginas do PDF. |
| `text` | Texto extraído de todas as páginas, reunido em um elemento. |
| `n_caracteres` | Tamanho do texto extraído, medido em caracteres. |

A coluna `text` terá esse nome porque costuma ser utilizada como entrada em pacotes de análise textual, que conheceremos mais adiante.

Vamos construir nossa função:

```{r definir-funcao-ler-pdf}
ler_pdf <- function(arquivo_pdf, pasta = "inteiro_teor") {

  caminho <- file.path(pasta, arquivo_pdf)

  paginas <- pdf_text(caminho)

  texto <- paste(paginas, collapse = "\n")

  tibble(
    id = as.integer(str_remove(arquivo_pdf, "\\.pdf$")),
    n_paginas = length(paginas),
    text = texto,
    n_caracteres = nchar(texto)
  )
}
```

Vamos entender as linhas novas.

`str_remove(arquivo_pdf, "\\.pdf$")` remove a extensão `.pdf` do nome do arquivo. O símbolo `$`, **dentro desse padrão de texto**, significa "final do texto": queremos retirar `.pdf` apenas quando ele aparece no final do nome. Não estamos utilizando `$` para selecionar uma coluna de um data frame.

Por exemplo, se o arquivo se chamar `123456.pdf`, a função `str_remove()` deixará apenas `123456`. `as.integer()` transforma esse texto em um número, para que possamos utilizar o `id` na associação com a tabela de proposições.

O restante já conhecemos: `pdf_text()` lê o arquivo; `paste()` junta suas páginas; `tibble()` cria uma linha com os resultados.

Vamos testar com nosso primeiro documento:

```{r testar-funcao-ler-pdf}
ler_pdf(arquivos_pdf[1]) %>%
  select(id, n_paginas, n_caracteres)
```

Não exibimos a coluna `text` porque ela pode conter muitas páginas. Mas o texto estará guardado no resultado da função.

# Construindo o corpus completo de PDFs

Agora vamos aplicar a função de leitura aos arquivos que baixamos. Se um PDF estiver danificado ou não puder ser interpretado, não queremos que isso apague os textos já obtidos.

Mais uma vez, podemos utilizar `possibly()`:

```{r criar-funcao-leitura-segura}
ler_pdf_seguro <- purrr::possibly(ler_pdf, otherwise = NULL)
```

Vamos iniciar nossa tabela:

```{r iniciar-corpus}
corpus_docs <- NULL
```

E agora o loop:

```{r construir-corpus}
for (arquivo_pdf in arquivos_pdf) {

  print(arquivo_pdf)

  linha_documento <- ler_pdf_seguro(arquivo_pdf)

  corpus_docs <- bind_rows(corpus_docs, linha_documento)

}
```

Reconhece a estrutura? É praticamente o mesmo loop que usamos para guardar os textos dos parques. A diferença é que agora **os documentos já estão no computador**: não precisamos fazer uma requisição à internet a cada iteração. `ler_pdf_seguro()` recebe o nome de um arquivo, tenta extrair seu texto e devolve uma linha.

Vamos conferir o resultado:

```{r conferir-corpus}
stopifnot(nrow(corpus_docs) > 0)

glimpse(corpus_docs)

corpus_docs %>%
  select(id, n_paginas, n_caracteres)
```

Nosso *data frame* agora tem uma linha para cada PDF lido com sucesso. Também podemos verificar se algum dos arquivos baixados não entrou no corpus:

```{r conferir-arquivos-lidos}
ids_arquivos <- arquivos_pdf %>%
  str_remove("\\.pdf$") %>%
  as.integer()

ids_lidos <- corpus_docs %>%
  pull(id)

ids_sem_texto <- setdiff(ids_arquivos, ids_lidos)

ids_sem_texto
```

Se aparecer algum identificador, o PDF correspondente não foi incorporado ao corpus. Precisamos investigar esse arquivo antes de apresentar a coleta como concluída.

## Examinando os tamanhos dos textos

Vamos usar `mutate()` para verificar quantos documentos ficaram sem texto extraível:

```{r examinar-tamanho-textos}
corpus_docs %>%
  mutate(sem_texto = n_caracteres == 0) %>%
  count(sem_texto)
```

Um documento pode ter sido lido corretamente e, ainda assim, produzir um texto vazio. Como vimos, isso pode ocorrer quando as páginas são imagens. A conferência ajuda a reconhecer esses casos, mas não substitui a leitura de uma amostra dos documentos.

Se quiser examinar o início do texto de uma proposição, podemos usar:

```{r examinar-exemplo-texto}
primeiro_texto <- corpus_docs %>%
  pull(text) %>%
  head(1)

substr(primeiro_texto, 1, 600)
```

Usamos `pull(text)` para extrair a coluna `text` como vetor, `head(1)` para escolher seu primeiro elemento e `substr()` para observar os caracteres iniciais. Reconhece a lógica? É a mesma combinação de operações que utilizamos para recuperar os endereços dos parques no Tutorial 3.

# Juntando o corpus aos metadados das proposições

Lembra que temos **duas tabelas**?

- `df_proposicoes` contém informações como número, ano, ementa e endereço de inteiro teor.
- `corpus_docs` contém o texto extraído de cada PDF e algumas informações sobre seu tamanho.

Queremos reunir tudo isso em **uma só tabela**, preservando uma linha por documento. É aqui que o identificador `id` se torna especialmente útil.

Vamos utilizar `left_join()`, do *dplyr*:

```{r juntar-metadados-ao-corpus}
corpus_docs <- corpus_docs %>%
  left_join(
    df_proposicoes %>%
      select(id, siglaTipo, numero, ano, dataApresentacao,
             ementa, urlInteiroTeor),
    by = "id"
  )

corpus_docs %>%
  select(id, siglaTipo, numero, ano, n_paginas, n_caracteres)
```

Leia a instrução: começamos pela tabela que contém os textos e procuramos, na tabela de metadados, as informações que possuem o mesmo `id`. O argumento `by = "id"` informa qual variável deve ser utilizada para relacionar as linhas.

Por que começar por `corpus_docs`? Porque queremos que cada linha do resultado continue correspondendo a **um PDF cujo texto tentamos extrair**. Não queremos criar linhas sem documento apenas porque existem metadados de outras proposições.

Vamos acrescentar a data da coleta:

```{r adicionar-data-da-coleta}
corpus_docs <- corpus_docs %>%
  mutate(data_coleta = Sys.Date())
```

Isso nos ajuda a lembrar **quando** obtivemos as informações. É importante porque uma API e os documentos disponibilizados por ela podem mudar ao longo do tempo.

Pronto! Nosso corpus contém os textos e os principais metadados das proposições correspondentes.

# Salvando o corpus e as tabelas de controle

Até aqui, os dados estão guardados na sessão do R. Vamos exportá-los para que possamos continuar o trabalho em outra aula, sem precisar fazer todos os downloads novamente.

Usaremos `write_csv2()`, do *readr*, para criar arquivos CSV. Essa função utiliza `;` para separar colunas, o que é conveniente em muitos programas configurados para o padrão brasileiro. Como a coluna `text` contém textos longos, o *readr* cuidará também da delimitação adequada desses conteúdos.

```{r exportar-resultados}
write_csv2(corpus_docs, "data/corpus_docs.csv")

write_csv2(df_proposicoes, "data/metadados_proposicoes.csv")

write_csv2(controle_download, "data/controle_downloads.csv")
```

Criamos três arquivos:

- `corpus_docs.csv`: os textos extraídos, os metadados e as informações sobre os PDFs.
- `metadados_proposicoes.csv`: os dados de todas as proposições cujos detalhes foram recuperados, inclusive aquelas sem PDF disponível.
- `controle_downloads.csv`: o registro de quais downloads de PDFs funcionaram e quais não funcionaram.

Os arquivos originais continuam guardados em `inteiro_teor`. Vale preservá-los, pois podemos querer examinar novamente algum documento ou refazer a extração de texto.

Se quisermos ler o corpus em outra sessão do R, podemos utilizar:

```{r reabrir-corpus, eval=FALSE}
corpus_docs <- read_csv2("data/corpus_docs.csv")
```

Esse comando está marcado para execução manual porque, no fluxo desta atividade, já temos o objeto `corpus_docs` na memória.

**Obs.:** a exportação registra o resultado **desta coleta**, não de todos os PLs apresentados em 2025. Não devemos confundir um exemplo de dez proposições com um levantamento exaustivo da produção legislativa.

# Código completo da atividade

Vamos agora juntar os comandos principais, sem as explicações, como fizemos nos tutoriais anteriores. Observe que o programa repete a mesma sequência que construímos com calma: **listar, detalhar, baixar, ler e guardar**.

O bloco está marcado com `eval=FALSE`: ele aparece no documento, mas **não será executado novamente durante o Knit**. Caso queira repetir a atividade do início, execute-o separadamente em uma nova sessão do R.

```{r codigo-completo, eval=FALSE}
library(httr2)
library(tidyverse)
library(pdftools)

dir.create("inteiro_teor", showWarnings = FALSE)
dir.create("data", showWarnings = FALSE)

# 1. Obter uma pequena lista de PLs de 2025.
url_proposicoes <- "https://dadosabertos.camara.leg.br/api/v2/proposicoes"

req <- request(url_proposicoes) %>%
  req_headers(Accept = "application/json") %>%
  req_url_query(siglaTipo = "PL", ano = 2025,
                ordem = "ASC", ordenarPor = "id", itens = 10)

resp <- req_perform(req)
df_proposicoes_simples <- as_tibble(
  resp_body_json(resp, simplifyVector = TRUE)$dados
)

ids_proposicoes <- df_proposicoes_simples %>% pull(id)

# 2. Buscar os detalhes e os endereços de inteiro teor.
obter_proposicao_detalhe <- function(id) {
  url <- paste0(url_proposicoes, "/", id)
  resp <- request(url) %>%
    req_headers(Accept = "application/json") %>%
    req_perform()
  proposicao <- resp_body_json(resp, simplifyVector = TRUE)$dados

  url_pdf <- proposicao$urlInteiroTeor
  if (is.null(url_pdf)) url_pdf <- NA_character_

  tibble(
    id = proposicao$id,
    siglaTipo = proposicao$siglaTipo,
    numero = proposicao$numero,
    ano = proposicao$ano,
    dataApresentacao = proposicao$dataApresentacao,
    ementa = proposicao$ementa,
    urlInteiroTeor = url_pdf
  )
}

obter_detalhe_seguro <- purrr::possibly(obter_proposicao_detalhe,
                                        otherwise = NULL)
df_proposicoes <- NULL

for (id in ids_proposicoes) {
  print(id)
  Sys.sleep(1)
  df_proposicoes <- bind_rows(df_proposicoes,
                              obter_detalhe_seguro(id))
}

stopifnot(nrow(df_proposicoes) > 0)

ids_obtidos <- df_proposicoes %>% pull(id)
ids_sem_detalhe <- setdiff(ids_proposicoes, ids_obtidos)

df_com_url <- df_proposicoes %>%
  filter(!is.na(urlInteiroTeor), nzchar(urlInteiroTeor))

# 3. Baixar e conferir os arquivos PDF.
baixar_inteiro_teor <- function(id, url, pasta = "inteiro_teor") {
  if (is.na(url) || !nzchar(url)) return(FALSE)
  resp <- request(url) %>% req_perform()
  conteudo <- resp_body_raw(resp)
  if (length(conteudo) < 4) return(FALSE)
  if (rawToChar(conteudo[1:4]) != "%PDF") return(FALSE)
  writeBin(conteudo, file.path(pasta, paste0(id, ".pdf")))
  TRUE
}

baixar_pdf_seguro <- purrr::possibly(baixar_inteiro_teor,
                                     otherwise = FALSE)

ids_download <- df_com_url %>% pull(id)
urls_download <- df_com_url %>% pull(urlInteiroTeor)
controle_download <- NULL

for (i in seq_along(ids_download)) {
  print(ids_download[i])
  Sys.sleep(1)
  baixou <- baixar_pdf_seguro(ids_download[i], urls_download[i])
  controle_download <- bind_rows(
    controle_download,
    tibble(id = ids_download[i], baixou_pdf = baixou)
  )
}

arquivos_pdf <- controle_download %>%
  filter(baixou_pdf) %>%
  mutate(arquivo_pdf = paste0(id, ".pdf")) %>%
  pull(arquivo_pdf)

stopifnot(length(arquivos_pdf) > 0)

# 4. Ler os PDFs e reunir seus textos.
ler_pdf <- function(arquivo_pdf, pasta = "inteiro_teor") {
  paginas <- pdf_text(file.path(pasta, arquivo_pdf))
  texto <- paste(paginas, collapse = "\n")
  tibble(
    id = as.integer(str_remove(arquivo_pdf, "\\.pdf$")),
    n_paginas = length(paginas),
    text = texto,
    n_caracteres = nchar(texto)
  )
}

ler_pdf_seguro <- purrr::possibly(ler_pdf, otherwise = NULL)
corpus_docs <- NULL

for (arquivo_pdf in arquivos_pdf) {
  print(arquivo_pdf)
  corpus_docs <- bind_rows(corpus_docs,
                           ler_pdf_seguro(arquivo_pdf))
}

stopifnot(nrow(corpus_docs) > 0)

# 5. Juntar os metadados e salvar os resultados.
corpus_docs <- corpus_docs %>%
  left_join(
    df_proposicoes %>%
      select(id, siglaTipo, numero, ano, dataApresentacao,
             ementa, urlInteiroTeor),
    by = "id"
  ) %>%
  mutate(data_coleta = Sys.Date())

write_csv2(corpus_docs, "data/corpus_docs.csv")
write_csv2(df_proposicoes, "data/metadados_proposicoes.csv")
write_csv2(controle_download, "data/controle_downloads.csv")
```

# Para praticar antes de avançar

**Primeiro exercício:** altere o número de registros pedidos à API de dez para cinco. Quantas consultas de detalhes serão necessárias? Quantos PDFs foram efetivamente baixados? As quantidades precisam ser iguais?

**Segundo exercício:** escolha um dos documentos e compare o texto extraído por `pdf_text()` com o PDF aberto em um leitor. Você consegue identificar o título, o corpo do projeto e as partes finais? Há quebras de linha ou outros elementos que precisariam ser tratados antes de uma análise textual?

**Terceiro exercício:** utilize `filter()` para selecionar apenas as proposições com `n_caracteres` acima de um valor escolhido por você. O que essa operação informa? Um texto maior é necessariamente um texto melhor para uma pesquisa?

**Exercício final:** imagine que sua pesquisa pretende comparar Projetos de Lei apresentados em 2024 e 2025. Que parte da consulta inicial precisaríamos modificar? Como poderíamos guardar o ano de cada documento? Por que seria importante registrar separadamente quais projetos não tiveram seus textos recuperados?

# Levando a coleta para uma pesquisa

Nesta atividade construímos um pequeno corpus, mas ainda não fizemos análise textual. Antes de interpretar os textos, precisamos pensar sobre a **seleção dos documentos**, a disponibilidade dos PDFs e a qualidade da extração.

Um PL apresentado em 2025 pode ter uma ementa muito curta e um texto original com várias páginas. A ementa e o inteiro teor não são a mesma coisa. Também devemos lembrar que documentos que não foram baixados ou lidos não desapareceram do universo de proposições: eles representam uma **limitação da coleta** que precisa ser registrada.

Além disso, a existência de um `id` e de um PDF não responde a uma pergunta de pesquisa por si só. Precisaremos decidir quais textos nos interessam, quais períodos vamos comparar e quais operações de preparação serão necessárias antes de contar palavras, construir frequências ou comparar conteúdos.

Se você compreendeu como **consultar os metadados, obter os arquivos, transformar PDFs em textos e reunir tudo em uma tabela**, já tem uma parte fundamental da construção de um corpus de pesquisa. Nas próximas atividades poderemos partir desse resultado para preparar os textos e analisá-los.

## [Extra] E se quisermos uma lista maior de PLs?

Para ampliar a lista de proposições, podemos utilizar o parâmetro `pagina` da API. Por exemplo, o bloco abaixo pede **duas páginas de até 100 registros** e reúne os resultados em uma tabela. Não execute a coleta completa de detalhes e PDFs imediatamente depois desse exemplo: primeiro observe quantos registros foram reunidos e decida se o volume é apropriado para sua pesquisa.

```{r exemplo-paginacao, eval=FALSE}
df_proposicoes_simples <- NULL

for (pagina in 1:2) {

  req <- request(url_proposicoes) %>%
    req_headers(Accept = "application/json") %>%
    req_url_query(siglaTipo = "PL", ano = 2025,
                  itens = 100, pagina = pagina,
                  ordem = "ASC", ordenarPor = "id")

  resp <- req_perform(req)
  corpo <- resp_body_json(resp, simplifyVector = TRUE)

  df_proposicoes_simples <- bind_rows(
    df_proposicoes_simples,
    as_tibble(corpo$dados)
  )

  Sys.sleep(1)
}

nrow(df_proposicoes_simples)
```

Observe a semelhança com o loop da Wikipedia: mudamos o número da página a cada iteração, capturamos os registros e acumulamos os resultados com `bind_rows()`.

**Obs.:** duas páginas não representam, necessariamente, todos os PLs de 2025. Uma coleta exaustiva precisaria percorrer todas as páginas disponíveis, conferir o número de registros e respeitar os limites e condições de acesso da API.

# Referências para consulta

- [Câmara dos Deputados — API de Dados Abertos](https://dadosabertos.camara.leg.br/swagger/api.html?tab=api). Consulte os endpoints `GET /proposicoes` e `GET /proposicoes/{id}` e os parâmetros `siglaTipo`, `ano`, `itens` e `pagina`.
- [Documentação do *httr2* — `req_perform()`](https://httr2.r-lib.org/reference/req_perform.html) e [`resp_body_raw()`](https://httr2.r-lib.org/reference/resp_body_raw.html). Explicam como executar requisições e recuperar o conteúdo de uma resposta.
- [Documentação do *pdftools* — `pdf_text()`](https://docs.ropensci.org/pdftools/reference/pdftools.html). Explica a extração de textos de páginas de PDFs.
- [Documentação do *pdftools* — OCR](https://docs.ropensci.org/pdftools/reference/pdf_ocr_text.html). Para consultas posteriores sobre documentos digitalizados como imagens.
- [Documentação do *dplyr* — `left_join()`](https://dplyr.tidyverse.org/reference/mutate-joins.html). Explica como relacionar tabelas por uma variável comum.
