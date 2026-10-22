---
title: "Tutorial 7 — Formulários na web: pesquisando teses e dissertações na BDTD"
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

Nos tutoriais anteriores, aprendemos a ler páginas HTML, localizar elementos usando seletores CSS e XPath, extrair textos e links e organizar informações em *data frames*. Também conhecemos a estrutura dos formulários utilizados nos sites para receber pesquisas.

Agora vamos trabalhar com a [Biblioteca Digital Brasileira de Teses e Dissertações (BDTD)](https://bdtd.ibict.br/vufind/), coordenada pelo Instituto Brasileiro de Informação em Ciência e Tecnologia (Ibict). A BDTD reúne registros de pesquisas de mestrado e doutorado realizadas em instituições brasileiras.

Continuaremos com nosso tema de trabalho: **parques nacionais**. Queremos utilizar o formulário da biblioteca para pesquisar esse assunto e coletar os **resumos das teses e dissertações encontradas**.

Vamos desenvolver a atividade em três etapas:

1. **Enviar uma pesquisa pelo formulário** e obter a página de resultados.
2. **Visitar um único trabalho** para entender como extrair seu resumo.
3. **Repetir a operação com um `for`**, reunindo os resumos em um data frame.

O objetivo é coletar os **resumos disponíveis nos registros da BDTD**, não baixar os documentos completos. Trabalharemos apenas com os resultados presentes na **primeira página** da pesquisa.

# Preparando o ambiente

Usaremos os mesmos pacotes das atividades anteriores: `rvest`, para acessar e extrair informações de páginas HTML, e `tidyverse`, para organizar os dados.

```{r pacotes}
library(rvest)
library(tidyverse)
```

Se precisar instalar esses pacotes, execute uma vez no console do R:

```{r instalar-pacotes, eval=FALSE}
install.packages(c("rvest", "tidyverse"))
```

# Pesquisando por meio de um formulário

Começaremos diretamente com a pesquisa. Primeiro lemos a página inicial da BDTD:

```{r ler-bdtd}
# Lemos o HTML da página inicial da biblioteca.
pagina_bdtd <- read_html("https://bdtd.ibict.br/vufind/")
```

Em seguida, selecionamos o formulário e preenchemos seu campo de pesquisa:

```{r preencher-formulario}
# Selecionamos o primeiro elemento <form> da página.
# html_form() permite preencher seus campos usando o R.
formulario <- pagina_bdtd %>%
  html_element("form") %>%
  html_form()

# Preenchemos o campo chamado 'lookfor' com o termo buscado.
formulario <- html_form_set(
  formulario,
  lookfor = "parques nacionais"
)

# Observamos o formulário preenchido.
formulario
```

Agora enviamos a pesquisa e lemos a resposta devolvida pelo servidor:

```{r enviar-formulario}
# Enviamos os valores do formulário ao servidor.
resposta <- html_form_submit(formulario)

# Lemos o HTML da página de resultados.
pagina_resultados <- read_html(resposta)

# Observamos o endereço gerado pela pesquisa.
resposta$url
```

**Já utilizamos um formulário da web sem abrir cada resultado manualmente.** A função `html_form_submit()` faz a solicitação e devolve uma resposta HTTP; `read_html()` transforma essa resposta em uma página que podemos examinar com o `rvest`.

## O que é um formulário HTML?

Em uma página da web, a tag `<form>` identifica um formulário. Dentro dela podemos encontrar campos, como `<input>`, e botões de envio.

Um exemplo simplificado de formulário de busca seria:

```html
<form action="/vufind/Search/Results" method="GET">
  <input type="text" name="lookfor">
  <button type="submit">Buscar</button>
</form>
```

Esse trecho serve apenas para ilustrar o funcionamento de um formulário; não é uma transcrição integral do HTML atual da BDTD.

Observe a correspondência entre `name="lookfor"` e a instrução `html_form_set(formulario, lookfor = "parques nacionais")`. O nome do campo é definido pelo site, não pelo R. Quando o formulário utiliza `GET`, os parâmetros da pesquisa costumam aparecer no endereço da página de resultados.

**Exercício:** substitua `"parques nacionais"` por `"unidades de conservação"`. Qual linha do código precisa mudar? Compare os endereços produzidos pelas duas pesquisas.

# Extraindo os links dos resultados

A página de resultados apresenta títulos de teses e dissertações que funcionam como links para seus registros bibliográficos.

Vamos selecionar esses elementos por meio de uma expressão XPath:

```{r selecionar-links}
# Selecionamos os links <a> que aparecem dentro de <h2>
# e possuem as classes 'title' e 'getFull'.
links <- pagina_resultados %>%
  html_elements(xpath = "//h2/a[@class='title getFull']")

# Quantos links encontramos nesta página?
length(links)
```

Na expressão `//h2/a[@class='title getFull']`, `//h2` procura elementos `<h2>`, `/a` seleciona os links dentro deles, e `[@class='title getFull']` restringe a seleção aos links com esse atributo.

Agora vamos extrair duas informações de cada link: o texto apresentado na página e o valor de seu atributo `href`.

```{r criar-tabela-registros}
# Criamos um data frame com os títulos e os endereços dos links.
tabela_registros <- tibble(
  titulo = html_text(links, trim = TRUE),
  url_registro = html_attr(links, "href")
)

# Transformamos os endereços relativos em URLs completas.
# Acrescentamos '#details', que aponta para a seção de detalhes
# bibliográficos quando a página é aberta no navegador.
tabela_registros <- tabela_registros %>%
  mutate(
    url_registro = xml2::url_absolute(
      url_registro,
      "https://bdtd.ibict.br/"
    ),
    url_registro = paste0(url_registro, "#details")
  )

# Observamos a tabela com os resultados da pesquisa.
tabela_registros

# Contamos quantos trabalhos aparecem na tabela.
nrow(tabela_registros)
```

Repare na diferença entre as funções: `html_text()` extrai o texto de um elemento HTML; `html_attr("href")` extrai o valor de um atributo. Já `url_absolute()` permite usar tanto links relativos quanto links que já estão completos.

A parte `#details` indica uma posição dentro da página para o navegador. **Ela não modifica a consulta ao servidor nem o conteúdo HTML que será recuperado.**

**Exercício:** escolha um dos endereços de `tabela_registros` e abra-o no navegador. Compare o título da tabela com o título apresentado no registro.

# Visitando um único trabalho

Antes de repetir a coleta, vamos entender como recuperar as informações de **apenas um registro**.

Selecionamos o primeiro endereço da tabela e lemos sua página HTML:

```{r abrir-primeiro-registro}
# Selecionamos o endereço do primeiro trabalho encontrado.
url_registro <- tabela_registros$url_registro[1]

# Lemos o HTML da página desse trabalho.
pagina_registro <- read_html(url_registro)

# Conferimos o endereço selecionado.
url_registro
```

## Localizando o resumo com XPath

No registro que estamos utilizando como exemplo, o resumo aparece em uma tabela HTML de informações bibliográficas. O seletor XPath abaixo recupera o conteúdo da **sexta linha** dessa tabela:

```{r extrair-primeiro-resumo}
# Localizamos a célula <td> da sexta linha da tabela
# de informações bibliográficas e extraímos seu texto.
resumo <- pagina_registro %>%
  html_element(
    xpath = '//table[@class="citation table table-striped"]/tr[6]/td'
  ) %>%
  html_text(trim = TRUE)

# Lemos o resumo recuperado.
resumo
```

Vamos interpretar a expressão XPath:

- `//table[@class="citation table table-striped"]` localiza a tabela com essas classes.
- `/tr[6]` seleciona sua sexta linha.
- `/td` seleciona a célula que contém o valor que queremos extrair.

Esse caminho foi construído a partir da estrutura HTML examinada na BDTD. **É importante conferir se o resumo ocupa essa posição nos outros trabalhos**, pois uma mudança na ordem dos campos pode fazer o código recuperar outra informação.

## Criando uma tabela com o primeiro resumo

O título do trabalho já está na tabela de resultados. Não precisamos extraí-lo novamente da página individual.

```{r primeiro-resultado}
# Recuperamos o título que já coletamos na busca.
titulo <- tabela_registros$titulo[1]

# Reunimos as três informações em um data frame.
resultado <- tibble(
  titulo = titulo,
  resumo = resumo,
  url_registro = url_registro
)

# Visualizamos a tabela com uma linha.
resultado
```

Cada coluna guarda uma informação sobre o trabalho. Essa é a estrutura que utilizaremos para formar um conjunto maior de resumos.

# Repetindo a coleta com um for loop

Já sabemos realizar a pesquisa e extrair um resumo. Agora queremos repetir a mesma operação com **todos os trabalhos encontrados na página de resultados**.

Em vez de criar uma tabela diferente para cada trabalho, vamos acrescentar uma coluna vazia à tabela de registros:

```{r preparar-coleta}
# Copiamos a tabela de títulos e links.
# Criamos uma coluna vazia para guardar os resumos.
resultados <- tabela_registros %>%
  mutate(resumo = NA_character_)

resultados
```

O valor `NA_character_` representa um valor de texto ainda não preenchido. A tabela já tem uma linha para cada trabalho; falta recuperar os resumos.

## O loop de coleta

Vamos usar um `for` para visitar os endereços da tabela, um por vez:

```{r coletar-todos-resumos}
# Percorremos todas as linhas do data frame de resultados.
for (i in seq_len(nrow(resultados))) {

  # Selecionamos o endereço do trabalho da posição atual.
  url_atual <- resultados$url_registro[i]

  # Lemos a página HTML desse trabalho.
  pagina_atual <- read_html(url_atual)

  # Extraímos o resumo usando o mesmo XPath do exemplo anterior.
  resumo_atual <- pagina_atual %>%
    html_element(
      xpath = '//table[@class="citation table table-striped"]/tr[6]/td'
    ) %>%
    html_text(trim = TRUE)

  # Guardamos o resumo na linha correspondente ao trabalho.
  resultados$resumo[i] <- resumo_atual

  # Fazemos uma pequena pausa antes de consultar outro registro.
  Sys.sleep(1)

}
```

A variável `i` representa a posição da linha que estamos preenchendo. Na primeira passagem, `i` vale `1`; na segunda, vale `2`; e assim por diante, até a última linha da tabela.

Observe que as operações dentro do `for` são praticamente as mesmas que utilizamos para o primeiro registro: **selecionar a URL, ler o HTML, extrair o resumo e guardar seu texto**. A pausa com `Sys.sleep(1)` evita solicitações em sequência imediata, mas não substitui as regras de acesso do site.

## Conferindo o resultado

Agora temos um data frame em que cada linha corresponde a um trabalho encontrado, com seu título, endereço e resumo:

```{r visualizar-resultados}
# Visualizamos o data frame completo.
resultados

# Conferimos quantas linhas temos.
nrow(resultados)
```

Podemos também conferir a quantidade de resumos encontrados:

```{r conferir-resumos}
# Contamos os resumos que não ficaram ausentes.
sum(!is.na(resultados$resumo))
```

Se um resumo aparecer como `NA`, precisamos conferir a página correspondente. Isso pode indicar que o campo está ausente ou que a estrutura HTML é diferente daquela utilizada no XPath.

# Salvando o corpus de resumos

Vamos salvar a tabela para utilizá-la nas próximas aulas, por exemplo, em análises de texto.

```{r salvar-corpus}
# Criamos a pasta 'data' se ela ainda não existir.
dir.create("data", showWarnings = FALSE)

# Salvamos todos os títulos, endereços e resumos em CSV.
write_csv(
  resultados,
  "data/bdtd_parques_nacionais_resumos.csv"
)
```

O arquivo CSV preserva o **título**, o **resumo** e a **URL do registro**. Guardar o endereço é importante para que possamos conferir de onde veio cada texto.

# Exercícios finais

1. Troque o termo de pesquisa para `"unidades de conservação"`. Quantos trabalhos aparecem na primeira página de resultados?
2. Abra um dos registros no navegador e compare seu resumo com o texto recuperado pelo código.
3. Observe o `for`: qual instrução faz com que cada resumo seja armazenado na linha correta do data frame?
4. Escolha outro assunto de seu interesse e crie um novo CSV de resumos. Quais partes do script precisaram mudar?

# Limites da coleta

Nossa tabela reúne **os registros encontrados na primeira página da pesquisa**, não todos os trabalhos existentes na BDTD sobre o assunto. Uma pesquisa pode ter outras páginas de resultados, que não percorremos neste tutorial.

Além disso, a busca pelo termo `"parques nacionais"` não representa necessariamente toda a produção acadêmica sobre o tema. Os resultados dependem do termo utilizado, das instituições participantes e dos metadados disponíveis.

**Atenção à estrutura HTML:** usamos um XPath que seleciona a sexta linha de uma tabela. Esse caminho é simples para fins de aprendizagem, mas depende da organização da página. Se os campos mudarem de posição, será necessário rever o seletor. Também pode acontecer de o portal alterar seu HTML ou apresentar uma página de verificação em vez dos resultados; nesse caso, confira a resposta recebida antes de tentar extrair os dados.

# Referências para consulta

- [BDTD — Biblioteca Digital Brasileira de Teses e Dissertações](https://bdtd.ibict.br/vufind/).
- [Ibict — Apresentação institucional da BDTD](https://www.gov.br/ibict/pt-br/site-ibict-2025/assuntos/informacao-cientifica/bdtd).
- [Documentação do `rvest`: formulários HTML](https://rvest.tidyverse.org/reference/html_form.html).
- [Documentação do `rvest`: seleção de elementos HTML](https://rvest.tidyverse.org/reference/html_element.html).
