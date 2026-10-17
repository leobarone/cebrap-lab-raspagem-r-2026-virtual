---
title: "Tutorial 7 — Formulários na web: buscando teses e dissertações na BDTD"
lang: pt-BR
output:
  html_document:
    toc: true
    toc_depth: 2
    number_sections: false
---

```{r configuracao, include=FALSE}
knitr::opts_chunk$set(echo = TRUE, message = FALSE, warning = FALSE)
```

# Apresentação do problema

Nos tutoriais anteriores aprendemos a extrair tabelas e textos de páginas HTML, seguir links com `read_html()`, repetir operações com `for loops` e construir um corpus. Também conhecemos formulários na web ao pesquisar artigos científicos no SciELO.

Vamos agora utilizar os mesmos conhecimentos em outra biblioteca digital: a [Biblioteca Digital Brasileira de Teses e Dissertações (BDTD)](https://bdtd.ibict.br/vufind/), coordenada pelo Instituto Brasileiro de Informação em Ciência e Tecnologia (Ibict).

A BDTD reúne informações sobre pesquisas de mestrado e doutorado realizadas em diferentes instituições brasileiras. Diferentemente do SciELO, **não estamos procurando artigos de periódicos**. Nossa unidade de observação será uma **tese ou dissertação**.

O assunto escolhido continua sendo **parques nacionais**, que utilizamos desde a primeira aula. Vamos preencher o formulário de busca da BDTD, obter os endereços dos trabalhos encontrados e visitar suas páginas para coletar os **resumos (*abstracts*) e os metadados bibliográficos**.

Ao final, construiremos um data frame em que cada linha representa um trabalho, com informações como:

| Coluna | Informação |
|:---|:---|
| `id_bdtd` | Identificador do registro na BDTD. |
| `titulo` | Título do trabalho. |
| `autor` | Nome da pessoa autora. |
| `ano` | Ano de defesa ou publicação indicado no registro. |
| `tipo_documento` | Tese ou dissertação. |
| `instituicao` | Instituição de defesa. |
| `programa` | Programa de pós-graduação, quando informado. |
| `orientador` | Orientação, quando informada. |
| `idioma` | Idioma indicado no registro. |
| `palavras_chave` | Assuntos ou palavras-chave do trabalho. |
| `resumo` | Texto do resumo disponível na BDTD. |
| `url_registro` | Endereço do registro na BDTD. |
| `url_documento` | Endereço do trabalho na instituição de origem, quando disponível. |
| `data_coleta` | Data em que consultamos o registro. |

**O objetivo não é baixar os PDFs.** A BDTD reúne os metadados, enquanto os arquivos completos permanecem nas instituições que produziram os trabalhos. Aqui queremos construir um **corpus de resumos**, semelhante, em sua organização, aos conjuntos de textos das atividades anteriores.

Trabalharemos primeiro com **uma única página de resultados** e depois com **um pequeno conjunto de registros**. Ao final, veremos como estender a coleta para todos os resultados encontrados naquela página.

**Obs.:** o acesso automatizado depende da resposta que a BDTD devolver no momento da aula. O portal pode modificar sua estrutura ou apresentar uma página de verificação do navegador. Se isso ocorrer, não devemos interpretar a página de verificação como se fosse um resultado de pesquisa nem tentar contornar o mecanismo. Os passos de conferência abaixo ajudam a reconhecer essa situação.

# Retomando a ideia de formulário

No Tutorial 6 aprendemos que o elemento HTML `form` identifica um formulário. Dentro dele podemos encontrar `input`, `select` e botões para enviar informações ao servidor.

A busca simples de um catálogo como a BDTD pode ser representada, **de maneira didática**, por um HTML parecido com este:

```html
<form action="/vufind/Search/Results" method="GET">
  <input type="text" name="lookfor">
  <select name="type">
    <option value="AllFields">Todos os campos</option>
    <option value="Title">Título</option>
  </select>
  <button type="submit">Buscar</button>
</form>
```

Esse trecho foi **simplificado para nossa explicação**. Não é uma transcrição integral do código atual do portal. Vamos inspecionar o formulário real em R.

Observe os nomes dos campos:

- `lookfor` corresponde à expressão que queremos pesquisar;
- `type` indica o campo do catálogo em que será realizada a busca, quando o formulário oferece essa escolha;
- `AllFields` significa procurar em todos os campos disponíveis.

No SciELO utilizamos um campo chamado `q`. Aqui utilizaremos `lookfor`. **O nome dos campos não é uma regra do R:** é uma decisão de quem construiu o formulário.

Repare também no método `GET`. Quando um formulário utiliza esse método, seus valores costumam aparecer no endereço da página de resultados, como acontece nas consultas que fizemos à API da Câmara.

**Exercício:** quais partes desse exemplo são tags HTML? Quais são atributos? O que aconteceria com o nome do parâmetro enviado ao servidor se trocássemos `name="lookfor"` por `name="termo"`?

# Preparando o ambiente

Vamos utilizar os mesmos pacotes que já conhecemos:

```{r carregar-pacotes}
library(rvest)
library(tidyverse)
```

Se precisar instalá-los, execute uma vez no console:

```{r instalar-pacotes, eval=FALSE}
install.packages(c("rvest", "tidyverse"))
```

O *rvest* será utilizado para trabalhar com o formulário e com as páginas HTML. O *tidyverse* será utilizado para organizar os resultados em data frames.

# Abrindo a BDTD e encontrando o formulário

Abra a [página inicial da BDTD](https://bdtd.ibict.br/vufind/) no navegador. Observe a caixa de busca, a opção de selecionar o campo de pesquisa e o botão **Buscar**.

Vamos criar uma sessão:

```{r criar-sessao-bdtd}
url_bdtd <- "https://bdtd.ibict.br/vufind/"

sessao_bdtd <- session(url_bdtd)

class(sessao_bdtd)
```

Lembre-se: `session()` cria um objeto que acompanha a navegação e pode conservar informações da comunicação com o servidor. A função não abre um navegador capaz de executar JavaScript.

Agora lemos a página recebida:

```{r ler-pagina-bdtd}
pagina_bdtd <- read_html(sessao_bdtd)

class(pagina_bdtd)
```

## Quais formulários existem na página?

Tal como fizemos no SciELO, vamos extrair os formulários com `html_form()`:

```{r listar-formularios-bdtd}
formularios_bdtd <- html_form(pagina_bdtd)

length(formularios_bdtd)
formularios_bdtd
```

O resultado é uma **lista de formulários**. Não vamos presumir que o formulário de busca esteja sempre na primeira posição.

Vamos examinar os nomes de seus campos:

```{r examinar-campos-bdtd}
for (i in seq_along(formularios_bdtd)) {
  cat("Formulário", i, ": ")
  cat(names(formularios_bdtd[[i]]$fields), "\n")
}
```

A função `names()` devolve os nomes dos campos. Os dois colchetes `[[i]]` extraem um formulário específico da lista, como já fizemos ao escolher uma tabela HTML.

Procure o campo `lookfor`. É ele que queremos preencher.

## Selecionando o formulário pelo nome do campo

Vamos começar com um objeto vazio:

```{r iniciar-formulario-bdtd}
formulario_busca <- NULL
```

Em seguida, percorremos a lista:

```{r localizar-formulario-bdtd}
for (formulario in formularios_bdtd) {

  if ("lookfor" %in% names(formulario$fields)) {
    formulario_busca <- formulario
    break
  }

}
```

Leia com calma: se o nome `lookfor` estiver entre os campos de um formulário, guardamos esse formulário e interrompemos a busca com `break`.

Vamos conferir:

```{r conferir-formulario-bdtd}
stopifnot(!is.null(formulario_busca))

formulario_busca
formulario_busca$method
formulario_busca$action
```

Se a verificação falhar, examine o HTML recebido. Pode ter ocorrido uma mudança no site ou o servidor pode ter devolvido uma página intermediária de verificação. Nesse caso, não devemos prosseguir como se o formulário tivesse sido encontrado.

# Preenchendo e enviando a pesquisa

Vamos buscar a expressão **parques nacionais**:

```{r preencher-formulario-bdtd}
formulario_busca <- formulario_busca %>%
  html_form_set(lookfor = "parques nacionais")

formulario_busca
```

Quando o formulário apresenta o campo `type`, também podemos conferir seu valor. Na busca simples do catálogo, `AllFields` corresponde à pesquisa em todos os campos. Por enquanto vamos utilizar a configuração oferecida pelo próprio formulário, sem acrescentar opções que não são necessárias.

O formulário já está preenchido, mas ainda não foi enviado. Para isso utilizamos `session_submit()`:

```{r submeter-formulario-bdtd}
sessao_resultados <- session_submit(
  x = sessao_bdtd,
  form = formulario_busca
)
```

Agora temos a sessão correspondente à página de resultados:

```{r ler-resultados-bdtd}
pagina_resultados <- read_html(sessao_resultados)

sessao_resultados$url
```

Compare esse endereço com o que aparece quando você realiza manualmente a mesma busca no navegador. Você poderá encontrar parâmetros como `lookfor=parques+nacionais` e `type=AllFields`.

O resultado deve apresentar uma lista de trabalhos, com títulos, autoria, ano e outras informações resumidas.

**Exercício:** repita a busca manualmente com `Parque Nacional da Tijuca`. Qual parte do endereço mudou? A estrutura geral do formulário é a mesma?

# Encontrando os links dos trabalhos

Nos tutoriais anteriores aprendemos a separar duas coisas: **selecionar elementos HTML** e **extrair seus textos ou atributos**.

Aqui faremos a mesma operação. Os títulos dos resultados da BDTD apontam para páginas de registros cujos endereços contêm o trecho `/Record/`.

Comecemos pelos elementos de link:

```{r selecionar-links-bdtd}
elementos_links_resultados <- pagina_resultados %>%
  html_elements(css = "a[href]")

length(elementos_links_resultados)
head(elementos_links_resultados)
```

Agora extraímos os textos e os valores do atributo `href`:

```{r extrair-links-bdtd}
rotulos_links <- elementos_links_resultados %>%
  html_text(trim = TRUE)

enderecos_links <- elementos_links_resultados %>%
  html_attr("href")

links_resultados <- tibble(
  rotulo = rotulos_links,
  endereco = enderecos_links
)

head(links_resultados)
```

É provável que também encontremos links para menus, filtros e outras partes do site. Vamos selecionar aqueles que apontam para registros de teses e dissertações.

## Completando os endereços e filtrando os registros

Lembre-se da distinção entre URLs absolutas e relativas que estudamos no Tutorial 2. O código a seguir funciona com ambas, porque utiliza `xml2::url_absolute()`:

```{r filtrar-registros-bdtd}
tabela_links_bdtd <- links_resultados %>%
  mutate(
    url_registro = xml2::url_absolute(endereco, sessao_resultados$url),
    url_registro = str_remove(url_registro, "[?#].*$"),
    url_registro = str_remove(url_registro, "/$")
  ) %>%
  filter(str_detect(url_registro, "/Record/[^/]+$")) %>%
  distinct(url_registro, .keep_all = TRUE) %>%
  select(rotulo, url_registro)

nrow(tabela_links_bdtd)
head(tabela_links_bdtd)
```

Vamos entender as operações:

- `url_absolute()` transforma endereços relativos em completos, quando necessário;
- `str_remove()` retira a parte posterior a `?` ou `#`, caso exista, e a barra final do endereço;
- `str_detect()` mantém endereços que terminam com o identificador de um registro;
- `distinct()` evita guardar duas vezes a mesma página;
- `select()` mantém apenas as colunas que queremos usar.

O trecho `/Record/` é uma característica da estrutura de endereços da BDTD. **Não é um seletor XPath ou CSS**, e sim um padrão que encontramos em um texto: o endereço do link.

Vamos conferir a quantidade:

```{r conferir-links-bdtd}
nrow(tabela_links_bdtd)
head(tabela_links_bdtd, 10)
```

Se o resultado estiver vazio, precisamos inspecionar os endereços originais e a resposta do servidor antes de avançar.

```{r verificar-links-bdtd}
stopifnot(nrow(tabela_links_bdtd) > 0)
```

Nossa seleção corresponde aos registros identificados **na página de resultados que recebemos**. Ainda não percorremos as outras páginas da pesquisa.

# Visitando o registro de um trabalho

Agora vamos recuperar o que fizemos no Tutorial 3: visitar **uma página de cada vez** antes de construir a repetição.

Primeiro criamos um vetor de endereços com `pull()`:

```{r criar-vetor-registros}
urls_registros <- tabela_links_bdtd %>%
  pull(url_registro)

head(urls_registros)
length(urls_registros)
```

Vamos escolher o primeiro:

```{r escolher-registro}
url_registro <- urls_registros[1]

url_registro
```

Abra esse endereço no navegador. A página não apresenta apenas um texto: ela organiza várias informações sobre o trabalho, como **título, autoria, ano de defesa, instituição, palavras-chave e resumo**.

Em um registro da BDTD, o resumo costuma aparecer identificado pelo rótulo **Resumo:**. Além disso, podemos encontrar outros rótulos, como **Autor(a) principal:** e **Tipo de documento:**.

Por exemplo, você pode examinar este [registro de uma dissertação sobre o Parque Nacional da Chapada Diamantina](https://bdtd.ibict.br/vufind/Record/UFV_7e798439cf31868947799921049f01df). O exemplo serve para identificar os campos da página; **nossa coleta continuará baseada nos resultados da pesquisa por parques nacionais**.

Vamos ler o registro que selecionamos:

```{r ler-primeiro-registro}
pagina_registro <- read_html(url_registro)
```

## Onde estão os metadados?

No Tutorial 2 aprendemos que tabelas HTML são organizadas em elementos `table`, `tr`, `th` e `td`. Essas estruturas também podem ser utilizadas para apresentar **campos e valores** de um registro bibliográfico.

Vamos começar examinando as linhas das tabelas da página:

```{r examinar-linhas-registro}
elementos_linhas_registro <- pagina_registro %>%
  html_elements(css = "table tr")

length(elementos_linhas_registro)
head(elementos_linhas_registro)
```

Queremos entender como localizar os pares **nome do campo / valor do campo**. Para isso, precisamos examinar as células de uma linha:

```{r examinar-celulas-registro}
if (length(elementos_linhas_registro) > 0) {
  elementos_celulas <- elementos_linhas_registro[[1]] %>%
    html_elements(css = "th, td")

  elementos_celulas %>% html_text(trim = TRUE)
}
```

O seletor `th, td` procura os dois tipos de célula. Dependendo da tabela, a primeira célula apresenta o nome do metadado, e a segunda guarda seu conteúdo.

**Atenção:** uma página pode ter outras tabelas, inclusive de navegação. Não basta encontrar muitas linhas: precisamos conferir se aparecem campos bibliográficos como `Resumo`, `Ano de defesa`, `author` ou `description`. Os registros da BDTD podem apresentar também uma tabela de **metadados técnicos**, com nomes de campos diferentes dos rótulos exibidos ao público.

# Transformando os metadados de uma página em uma tabela

Vamos construir uma função pequena. Ela receberá uma página HTML e devolverá uma tabela com os pares **campo / valor** encontrados nas linhas das tabelas.

Como você já conhece `for loops`, podemos fazer isso sem aprender uma técnica inteiramente nova.

```{r definir-funcao-campos}
extrair_campos <- function(pagina) {

  linhas <- pagina %>% html_elements(css = "table tr")
  tabela_campos <- NULL

  for (linha in linhas) {

    celulas <- linha %>% html_elements(css = "th, td")

    if (length(celulas) < 2) next

    campo <- celulas[[1]] %>% html_text(trim = TRUE)
    valor <- celulas[[2]] %>% html_text(trim = TRUE)

    campo <- str_remove(campo, ":$") %>% str_squish()
    valor <- str_squish(valor)

    if (campo == "") next

    link <- celulas[[2]] %>% html_element(css = "a[href]")

    endereco <- if (inherits(link, "xml_missing")) {
      NA_character_
    } else {
      html_attr(link, "href")
    }

    linha_campo <- tibble(
      campo = campo,
      valor = valor,
      endereco = endereco
    )

    tabela_campos <- bind_rows(tabela_campos, linha_campo)
  }

  tabela_campos
}
```

Vamos explicar as instruções que ainda não havíamos utilizado em conjunto.

`if (length(celulas) < 2) next` significa: quando uma linha tiver menos de duas células, pule essa iteração e continue examinando as outras linhas. A palavra `next` faz essa passagem para a próxima iteração.

`str_squish()` retira espaços excedentes e quebras de linha que não são necessárias para guardar o texto em uma coluna. É útil quando uma célula apresenta um resumo longo.

Também procuramos um elemento `a` dentro da segunda célula. Isso nos permite conservar o **endereço do documento na instituição de origem**, quando ele aparece como link. Se não houver link, guardamos `NA`.

Por fim, `bind_rows()` acrescenta uma linha à tabela, como já fizemos nos tutoriais sobre coleta de textos.

Vamos experimentar:

```{r extrair-campos-primeiro-registro}
campos_registro <- extrair_campos(pagina_registro)

campos_registro %>%
  select(campo, valor) %>%
  print(n = 30)
```

Procure os campos que nos interessam. Os nomes podem variar: além de `Resumo`, podemos encontrar, por exemplo, o metadado técnico `description`; além de `Ano de defesa`, podemos encontrar `publishDate`.

Se a página não apresentar linhas com esses campos, interrompa a atividade e examine seu HTML antes de avançar. Um resultado vazio também pode indicar que não recebemos o registro esperado.

# Selecionando os campos que nos interessam

Imagine que criamos a tabela abaixo, com três linhas:

| campo | valor |
|:---|:---|
| `title` | Título de uma dissertação |
| `author` | Nome da pessoa autora |
| `publishDate` | 2018 |

Queremos recuperar um único valor associado a determinado nome de campo. Já sabemos fazer isso com `filter()` e `pull()`:

```{r exemplo-selecionar-campo}
exemplo_metadados <- tibble(
  campo = c("title", "author", "publishDate"),
  valor = c("Título de uma dissertação", "Nome da pessoa autora", "2018")
)

exemplo_metadados %>%
  filter(campo == "author") %>%
  pull(valor)
```

Mas nem todos os registros possuem todas as informações. Uma instituição pode não ter enviado o programa de pós-graduação ou o orientador, por exemplo. Portanto, precisamos de uma função que devolva `NA` quando o campo não estiver disponível.

```{r definir-funcao-valor}
obter_valor <- function(tabela, nomes) {

  valores <- tabela %>%
    filter(str_to_lower(campo) %in% str_to_lower(nomes)) %>%
    filter(!is.na(valor), valor != "") %>%
    pull(valor)

  if (length(valores) == 0) {
    return(NA_character_)
  }

  valores[1]
}
```

Note que o argumento `nomes` pode receber um vetor. Dessa maneira, podemos procurar por `Resumo` e, caso ele não exista, por `description`.

Vamos testar:

```{r experimentar-obter-valor}
obter_valor(exemplo_metadados, c("author", "Autor(a) principal"))
obter_valor(exemplo_metadados, c("instituicao", "Instituição de defesa"))
```

A segunda consulta retorna `NA`, pois não há esse campo em nossa pequena tabela de exemplo.

## Recuperando o resumo e os demais metadados

Agora podemos construir uma função que realiza todas as operações em **um registro**.

Ela receberá o endereço de uma tese ou dissertação, lerá a página, transformará os campos em uma tabela e selecionará os valores que queremos guardar.

```{r definir-funcao-registro}
obter_metadados <- function(url_registro) {

  pagina <- read_html(url_registro)
  campos <- extrair_campos(pagina)

  if (is.null(campos) || nrow(campos) == 0) {
    stop("Não encontramos os metadados esperados nesta página.")
  }

  titulo_pagina <- pagina %>%
    html_elements(css = "h1") %>%
    html_text(trim = TRUE)

  titulo <- obter_valor(campos, c("title", "Título"))

  if (is.na(titulo) && length(titulo_pagina) > 0) {
    titulo <- titulo_pagina[1]
  }

  resumo <- obter_valor(campos, c("Resumo", "description"))

  ano_texto <- obter_valor(campos, c("Ano de defesa", "publishDate"))
  ano <- str_extract(ano_texto, "[0-9]{4}")

  link_original <- campos %>%
    filter(str_to_lower(campo) == "link de acesso") %>%
    pull(endereco)

  link_original <- link_original[!is.na(link_original)]

  if (length(link_original) == 0) {
    link_original <- obter_valor(campos, c("url"))
  } else {
    link_original <- link_original[1]
  }

  tibble(
    id_bdtd = str_extract(url_registro, "(?<=/Record/)[^/?#]+"),
    titulo = titulo,
    autor = obter_valor(campos, c("Autor(a) principal", "author")),
    ano = ano,
    tipo_documento = obter_valor(campos, c("Tipo de documento", "format")),
    instituicao = obter_valor(campos, c("Instituição de defesa", "instname_str")),
    programa = obter_valor(campos, c("Programa de Pós-Graduação")),
    orientador = obter_valor(campos, c("Orientador(a)")),
    idioma = obter_valor(campos, c("Idioma", "language")),
    palavras_chave = obter_valor(campos, c("Palavras-chave em Português", "topic")),
    resumo = resumo,
    url_registro = url_registro,
    url_documento = link_original,
    data_coleta = as.character(Sys.Date())
  )
}
```

Agora vamos executar para um único trabalho:

```{r obter-primeiro-registro}
primeiro_trabalho <- obter_metadados(url_registro)

primeiro_trabalho %>%
  select(titulo, autor, ano, tipo_documento, instituicao, resumo)
```

Leia algumas partes dessa função com atenção.

`obter_valor()` recupera os campos por seus nomes, sem depender da ordem em que aparecem nas tabelas HTML. Isso é importante porque um trabalho pode apresentar mais informações do que outro.

`str_extract(ano_texto, "[0-9]{4}")` procura uma sequência de quatro algarismos no texto do ano. O resultado é guardado como texto; nesta atividade, isso é suficiente.

Já `str_extract(url_registro, "(?<=/Record/)[^/?#]+")` extrai o identificador do trabalho a partir de seu endereço. Ele funciona como uma chave para distinguir os registros e manter a referência à origem.

Observe também que o resumo é guardado como **um único texto** na coluna `resumo`. É diferente do Tutorial 5, no qual lemos um PDF e tivemos de reunir o conteúdo de diversas páginas.

**Exercício:** consulte um trabalho no navegador e compare seu resumo e sua instituição com os valores da tabela. Se algum campo vier vazio, procure primeiro verificar se ele está disponível no registro original.

# Repetindo a operação para um pequeno conjunto de trabalhos

Já sabemos coletar uma página. Agora vamos repetir a operação como fizemos na Wikipedia, no SciELO e na API da Câmara.

Para a primeira tentativa, escolhemos até cinco endereços:

```{r selecionar-teste-bdtd}
urls_teste <- head(urls_registros, 5)

urls_teste
```

Queremos que **cada iteração produza uma linha**. Ao final, teremos um data frame com os metadados e os resumos dos trabalhos consultados.

Como aprendemos no Tutorial 5, uma solicitação pode falhar. Utilizaremos `possibly()`, do pacote *purrr*, para que uma falha não interrompa toda a coleta pequena.

```{r criar-funcao-segura-bdtd}
obter_metadados_seguro <- purrr::possibly(
  obter_metadados,
  otherwise = NULL
)
```

A função original continua existindo e poderá ser chamada diretamente quando quisermos investigar um erro. A versão segura devolve `NULL` se ocorrer uma falha.

Vamos começar com um objeto vazio e acrescentar uma linha a cada visita:

```{r coletar-teste-bdtd}
corpus_resumos_bdtd <- NULL

for (url_registro in urls_teste) {

  print(url_registro)
  Sys.sleep(2)

  linha_trabalho <- obter_metadados_seguro(url_registro)

  if (is.null(linha_trabalho)) {
    message("Falha na leitura deste registro: ", url_registro)
    next
  }

  corpus_resumos_bdtd <- bind_rows(
    corpus_resumos_bdtd,
    linha_trabalho
  )

}
```

A pausa com `Sys.sleep(2)` evita solicitações em sequência muito rápida. Ela não substitui as condições de uso do site.

O `if` verifica se a leitura falhou. Quando isso acontece, imprimimos uma mensagem e utilizamos `next` para continuar no endereço seguinte. **Isso não significa que coletamos tudo**: precisamos registrar e conferir as ausências.

# Conferindo o corpus

Vamos examinar os resultados:

```{r examinar-corpus-bdtd}
if (!is.null(corpus_resumos_bdtd)) {
  glimpse(corpus_resumos_bdtd)
  head(corpus_resumos_bdtd)
}
```

A primeira conferência é comparar o número de endereços visitados com o número de linhas obtidas:

```{r conferir-quantidades-bdtd}
length(urls_teste)

if (!is.null(corpus_resumos_bdtd)) {
  nrow(corpus_resumos_bdtd)
}
```

Também vamos criar uma pequena tabela de controle. Assim saberemos quais endereços entraram no resultado:

```{r controlar-coleta-bdtd}
urls_coletadas <- if (is.null(corpus_resumos_bdtd)) {
  character()
} else {
  corpus_resumos_bdtd %>% pull(url_registro)
}

controle_coleta <- tibble(
  url_registro = urls_teste,
  coletado = urls_teste %in% urls_coletadas
)

controle_coleta
```

Se algum registro não foi coletado, podemos executar `obter_metadados(url)` diretamente para ver qual erro ocorreu.

## Há resumos em todos os registros?

Um corpus de resumos é diferente de uma tabela de links. Precisamos conferir se o conteúdo textual está realmente presente.

```{r conferir-resumos-bdtd}
if (!is.null(corpus_resumos_bdtd)) {

  conferencia <- corpus_resumos_bdtd %>%
    mutate(n_caracteres = nchar(resumo)) %>%
    select(titulo, ano, tipo_documento, n_caracteres)

  conferencia
}
```

Um valor `NA` indica que o resumo não foi encontrado com os critérios utilizados. Um texto muito curto também merece atenção. Nem todo registro enviado à BDTD tem necessariamente todos os campos preenchidos da mesma maneira.

Para ler um resumo no console, podemos utilizar `cat()`:

```{r ler-resumo-bdtd, eval=FALSE}
resumos <- corpus_resumos_bdtd %>% pull(resumo)
cat(resumos[1])
```

Assim como nos exercícios anteriores, não é necessário imprimir todos os resumos longos de uma vez.

# Salvando o corpus de resumos

Vamos criar uma pasta para guardar o resultado:

```{r criar-pasta-dados-bdtd}
dir.create("data", showWarnings = FALSE)
```

Se a coleta encontrou ao menos um registro, podemos exportar o data frame:

```{r salvar-corpus-bdtd}
if (!is.null(corpus_resumos_bdtd)) {
  write_csv(corpus_resumos_bdtd, "data/bdtd_parques_nacionais_resumos.csv")
}

write_csv(controle_coleta, "data/bdtd_controle_coleta.csv")
```

A função `write_csv()` guarda as colunas e os textos em um arquivo CSV. É importante conservar também as URLs, para que possamos voltar à fonte dos dados.

**Obs.:** o corpus reúne os resumos das teses e dissertações, **não os textos completos dos trabalhos**. Os resumos podem apresentar versões em idiomas diferentes e nem todas as instituições preenchem os campos da mesma forma. Essas diferenças fazem parte dos dados e precisam ser consideradas antes da análise.

# Da coleta de teste para todos os resultados da página

Para coletar todos os registros **da página de resultados que já capturamos**, basta percorrer `urls_registros` em vez de `urls_teste`.

A lógica da repetição é a mesma. Vamos deixar o código pronto, mas não o executar automaticamente na compilação do RMarkdown:

```{r coleta-da-pagina-completa, eval=FALSE}
corpus_resumos_bdtd <- NULL

for (url_registro in urls_registros) {

  print(url_registro)
  Sys.sleep(2)

  linha_trabalho <- obter_metadados_seguro(url_registro)

  if (is.null(linha_trabalho)) {
    message("Falha na leitura: ", url_registro)
    next
  }

  corpus_resumos_bdtd <- bind_rows(
    corpus_resumos_bdtd,
    linha_trabalho
  )
}

write_csv(corpus_resumos_bdtd, "data/bdtd_parques_nacionais_resumos.csv")
```

**Atenção:** isso ainda não significa que coletamos **todos os resultados da pesquisa no catálogo**. Uma busca pode ocupar várias páginas. Nosso vetor `urls_registros` contém apenas as páginas de registro cujos links estavam no primeiro resultado recebido. Para ampliar o universo será necessário percorrer a paginação, reunir os endereços e retirar as repetições antes de visitar cada registro.

## [Extra] Pensando na paginação

Observe no navegador como a BDTD permite passar para a página seguinte dos resultados. Em buscas dessa interface, podemos encontrar o parâmetro `page` no endereço.

Antes de automatizar a navegação, faça duas pesquisas manualmente e compare seus endereços. Se a busca que fizemos continuar expressa em um endereço com parâmetros `GET`, uma segunda página pode ser representada por `page=2`.

Não precisamos escrever essa rotina agora. O exercício principal é compreender como **um formulário dá origem a um conjunto de links e como cada link pode produzir uma linha de dados**.

**Desafio:** como você reuniria os endereços das duas primeiras páginas de resultados em um único vetor, removendo repetições? Como evitaria visitar o mesmo registro duas vezes?

# Levando o procedimento para uma pesquisa

Já conseguimos combinar duas habilidades que estudamos separadamente:

1. **Enviar uma pesquisa por formulário**, definindo qual informação desejamos recuperar.
2. **Visitar os resultados e construir um corpus**, conservando metadados e texto na mesma tabela.

Com esse corpus podemos investigar, por exemplo, quais instituições aparecem nos resultados sobre parques nacionais, como os trabalhos se distribuem ao longo dos anos e quais expressões são mais frequentes nos resumos.

Mas precisamos tomar cuidado com o significado dos dados. Uma busca pelo termo `parques nacionais` não equivale a um levantamento exaustivo de toda a produção científica sobre o assunto. Os resultados dependem da estratégia de busca, da cobertura das instituições participantes, da qualidade dos metadados e da paginação que efetivamente percorremos.

**Exercício final:** troque o assunto da pesquisa para `unidades de conservação`. Que partes do código precisam mudar? Quais funções e operações continuam exatamente iguais? Como você distinguiria a população de trabalhos encontrada em cada uma das pesquisas?

# Referências para consulta

- [BDTD — Biblioteca Digital Brasileira de Teses e Dissertações](https://bdtd.ibict.br/vufind/).
- [Ibict — Apresentação institucional da BDTD](https://www.gov.br/ibict/pt-br/site-ibict-2025/assuntos/informacao-cientifica/bdtd).
- [BDTD — Perguntas frequentes](https://bdtd.ibict.br/vufind/faq/home).
- [Documentação do `rvest`: formulários HTML](https://rvest.tidyverse.org/reference/html_form.html).
- [Documentação do `rvest`: submissão de formulários](https://rvest.tidyverse.org/reference/session_submit.html).
- [Documentação do `rvest`: seleção de elementos HTML](https://rvest.tidyverse.org/reference/html_element.html).
