# Carregando os pacotes
library(tidyverse)
library(rvest)

install.packages('rvest')

# URL da pagina com a lista de parques nacionais
url_lista_parques <- 'https://pt.wikipedia.org/wiki/Lista_de_parques_nacionais_do_Brasil'

# Capturando o HTML da pagina
pagina_lista_parques <- read_html(url_lista_parques)

# Extraindo todas as tabelas da pagina
tabelas_pagina <- pagina_lista_parques %>% 
  html_table()

tabelas_pagina <- html_table(pagina_lista_parques) 
  
# Selecionando a primeira tabela da lista
tabela_parques <- tabelas_pagina[[1]]

# Extraindo os links presentes nos cabeçalhos das tabelas
url_parques <- pagina_lista_parques %>% 
  html_nodes(xpath = '//table//tr/th//a') %>% 
  html_attr('href')

# Mantendo apenas os links completos da Wikipedia
url_parques <- url_parques %>% 
  str_subset('https://pt.wikipedia.org/wiki/')

# Selecionando os primeiros 76 links
url_parques <- url_parques[1:76]

for (url_p in url_parques){
  print(url_p)
  pagina <- read_html(url_p)
}



# Criando um objeto vazio para armazenar os textos
tabela_textos <- NULL

# Percorrendo os links dos parques
for (url_p in url_parques) {
  
  # Mostrando o link que esta sendo capturado
  print(url_p)
  
  # Capturando o HTML da pagina do parque
  pagina_parque <- read_html(url_p)
  
  # Extraindo os textos dos parágrafos da página
  texto <- pagina_parque %>% 
    html_nodes(xpath = '//p') %>% 
    html_text()
  
  # Reunindo os parágrafos em um unico texto
  texto <- paste0(texto, collapse = "")
  
  # Armazenando o link e o texto em uma nova linha da tabela
  tabela_textos <- tabela_textos %>% 
    bind_rows(
      tibble(
        url_pagina_parque = url_p,
        texto_parque = texto
      )
    )
  
}

df <- bind_cols(tibble(id=1:76), tabela_parques, tabela_textos) %>% janitor::clean_names() 

bind_cols(tibble(id=1:76), tabela_parques, tabela_textos) %>% janitor::clean_names() %>% write_csv2('tabelas-parques-utf8,csv')
