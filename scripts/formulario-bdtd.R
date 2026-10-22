# ============================================================
# TUTORIAL 7
# FORMULÁRIOS NA WEB: PESQUISANDO TESES E DISSERTAÇÕES NA BDTD
# ============================================================


# 1. PREPARAÇÃO DO AMBIENTE
# ------------------------------------------------------------

# Carregamos os pacotes que utilizaremos na atividade.
# O rvest permite trabalhar com formulários e páginas HTML.
# O tidyverse ajuda a organizar os dados coletados.

# install.packages(c("rvest", "tidyverse"))

library(rvest)
library(tidyverse)


# 2. REALIZANDO UMA PESQUISA POR FORMULÁRIO
# ------------------------------------------------------------

# Vamos pesquisar trabalhos acadêmicos sobre parques nacionais
# na Biblioteca Digital Brasileira de Teses e Dissertações (BDTD).

# Primeiro, lemos o HTML da página inicial da biblioteca.

pagina_bdtd <- read_html("https://bdtd.ibict.br/vufind/")


# Localizamos o formulário de pesquisa usando a tag <form>.
# A função html_form() transforma esse elemento HTML em um
# objeto que podemos preencher diretamente pelo R.

formulario <- pagina_bdtd %>%
  html_element("form") %>%
  html_form()


# Preenchemos o campo 'lookfor' com nossa expressão de busca.
# Esse nome corresponde ao atributo 'name' do campo no HTML.

formulario <- html_form_set(
  formulario,
  lookfor = "parques nacionais"
)


# Podemos visualizar o formulário com o campo preenchido.

formulario


# Agora enviamos o formulário ao servidor.
# A função html_form_submit() realiza a solicitação HTTP.

resposta <- html_form_submit(formulario)


# Transformamos a resposta em um documento HTML,
# que contém os resultados da nossa pesquisa.

pagina_resultados <- read_html(resposta)


# Consultamos o endereço produzido pela pesquisa.

resposta$url



# 3. EXTRAINDO OS LINKS DOS RESULTADOS
# ------------------------------------------------------------

# A página de resultados apresenta títulos de teses e
# dissertações que funcionam como links para seus registros.

# Utilizamos XPath para selecionar os links que aparecem
# dentro de elementos <h2> e possuem as classes
# 'title' e 'getFull'.

links <- pagina_resultados %>%
  html_elements(xpath = "//h2/a[@class='title getFull']")


# Podemos observar os elementos encontrados.

links


# Quantos links foram identificados?

length(links)


# Agora vamos transformar esses elementos em uma tabela.
#
# html_text() recupera o texto apresentado no link.
# html_attr() recupera o atributo href, que contém o endereço.

tabela_registros <- tibble(
  titulo = html_text(links, trim = TRUE),
  url_registro = html_attr(links, "href")
)


# Os endereços extraídos podem ser relativos.
# Vamos transformá-los em endereços completos.
#
# Acrescentamos '#details' ao final para apontar para a
# seção de detalhes bibliográficos no navegador.

tabela_registros <- tabela_registros %>%
  mutate(
    url_registro = xml2::url_absolute(
      url_registro,
      "https://bdtd.ibict.br/"
    ),
    url_registro = paste0(url_registro, "#details")
  )


# Visualizamos a tabela de títulos e endereços.

View(tabela_registros)


# Contamos quantos trabalhos foram encontrados.

nrow(tabela_registros)



# 4. VISITANDO UM ÚNICO REGISTRO
# ------------------------------------------------------------

# Já temos uma tabela com os títulos e links dos trabalhos.
# Agora vamos visitar um deles para recuperar seu resumo.

# Escolhemos o endereço do primeiro trabalho encontrado.

url_registro <- tabela_registros$url_registro[1]


# Visual