---
title: "Tutorial 1 — Capturando uma tabela de parques nacionais na Wikipedia"
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

Vamos começar visitando a página da [Wikipedia que apresenta a lista de parques nacionais do Brasil](https://pt.wikipedia.org/wiki/Lista_de_parques_nacionais_do_Brasil). Abra o link no navegador e observe o conteúdo da página antes de continuar a atividade.

Há bastante informação, não? Além do texto de apresentação, a página contém uma tabela com nomes de parques, localização, data de criação e outras características. Nosso objetivo nesta primeira atividade será **capturar essa tabela e transformá-la em um data frame no R**.

Poderíamos copiar e colar as informações manualmente. Mas imagine fazer isso com dezenas de tabelas, ou repetir a coleta para acompanhar as mudanças de uma página. É aí que entra a raspagem de dados: vamos escrever instruções para que o computador acesse a página e extraia as informações que nos interessam.

Vamos manter o código bastante simples. A ideia não é construir um programa sofisticado de coleta, mas compreender o que acontece em cada etapa.

Ao longo destes três tutoriais, vamos avançar de uma tabela pronta para a coleta dos textos de várias páginas. **Neste primeiro tutorial, porém, ficaremos apenas com a tabela.** Os links dos parques e os textos das páginas serão o nosso próximo desafio.

# Pacotes no R

Algumas das funções que vamos utilizar não fazem parte das funções básicas do R. Precisamos, portanto, instalar dois pacotes: *rvest* e *tidyverse*.

O *rvest* contém funções para capturar páginas de internet e extrair informações de documentos HTML. O *tidyverse* reúne pacotes que já começamos a utilizar para trabalhar com dados, como o *dplyr*.

A instalação precisa ser feita apenas uma vez em cada computador. Caso os pacotes ainda não estejam instalados, execute:

```{r instalar-pacotes, eval=FALSE}
install.packages("rvest")
install.packages("tidyverse")
```

Uma vez instalados, os pacotes não ficam automaticamente disponíveis em todas as sessões. Precisamos **chamá-los** com a função `library()`:

```{r carregar-pacotes}
library(rvest)
library(tidyverse)
```

Excelente! Já temos as funções necessárias.

**Obs.:** chamar o *tidyverse* não carrega automaticamente o *rvest*. Por isso usamos os dois comandos. A instalação e o carregamento de um pacote são operações diferentes: instalar coloca o pacote no computador; `library()` disponibiliza suas funções na sessão em que estamos trabalhando.[^pacotes]

# Guardando o endereço de uma página

Nossa primeira tarefa consiste em armazenar o endereço da página que queremos capturar. Vamos criar um objeto chamado `url_lista_parques`:

```{r guardar-url}
url_lista_parques <- "https://pt.wikipedia.org/wiki/Lista_de_parques_nacionais_do_Brasil"
```

Vamos observar esse objeto:

```{r examinar-url}
url_lista_parques
class(url_lista_parques)
```

O objeto contém um texto, isto é, pertence à classe `character`.

Até agora, **não acessamos a página**. Apenas guardamos seu endereço. É como anotar o endereço de uma biblioteca: sabemos onde ela fica, mas ainda não entramos para consultar os livros.

Guarde essa diferença. O endereço de uma página e o conteúdo de uma página não são a mesma coisa.

# Capturando a página com `read_html()`

Para acessar a página e guardar seu conteúdo HTML no R, utilizaremos a função `read_html()`, do pacote *rvest*:

```{r capturar-pagina}
pagina_lista_parques <- read_html(url_lista_parques)
```

Vamos ler a instrução: usamos o texto guardado em `url_lista_parques` como argumento de `read_html()` e armazenamos o resultado no objeto `pagina_lista_parques`.

A função faz uma solicitação ao servidor e interpreta o HTML recebido. É esse documento interpretado que passa a existir na nossa sessão de R.[^read-html]

Mas o que há dentro do objeto? Vamos utilizar duas funções que já conhecemos:

```{r examinar-pagina}
class(pagina_lista_parques)
print(pagina_lista_parques)
```

O resultado de `class()` identifica um objeto das classes `xml_document` e `xml_node`. O resultado de `print()` mostra um resumo da estrutura da página, e não a página diagramada como aparece no navegador.

Estranho, não? Ainda não temos um data frame.

Por enquanto, basta compreender que capturamos um documento com uma estrutura que o R consegue examinar. Essa estrutura informa onde estão elementos como títulos, parágrafos, tabelas e links. No próximo tutorial veremos com mais cuidado o que são HTML e XML e por que aparecem esses nomes.

Agora vamos começar pelo caso mais fácil: uma tabela que já está organizada na página.

# Extraindo as tabelas com `html_table()`

A função `html_table()`, também do *rvest*, procura tabelas no documento HTML e as transforma em objetos que podemos manipular no R.[^html-table]

```{r extrair-tabelas}
tabelas_pagina <- pagina_lista_parques %>%
  html_table()
```

Note o símbolo `%>%`, que já utilizamos com o *dplyr*. Podemos ler o código assim: **pegue o objeto `pagina_lista_parques` e passe-o para a função `html_table()`**. O resultado será guardado em `tabelas_pagina`.

Também poderíamos escrever a mesma instrução sem o *pipe*:

```{r extrair-sem-pipe, eval=FALSE}
tabelas_pagina <- html_table(pagina_lista_parques)
```

Não são duas etapas. São duas maneiras de escrever a mesma operação. Basta executar uma delas.

Vamos examinar o resultado:

```{r examinar-tabelas}
class(tabelas_pagina)
length(tabelas_pagina)
```

O resultado é uma **lista**. Por quê?

Porque uma página pode conter mais de uma tabela. Em vez de escolher uma delas por nós, a função devolve uma lista na qual cada posição contém uma tabela.

**Obs.:** aqui aplicamos `html_table()` ao documento inteiro. Mais adiante aprenderemos a selecionar uma única tabela ainda dentro do HTML. Quando recebe apenas esse elemento, a função pode devolver diretamente uma tabela, e não uma lista.

# Listas e seus elementos

Vale recuperar uma particularidade das listas no R. Uma lista é uma estrutura que pode guardar diferentes objetos. No nosso caso, os objetos guardados são tabelas.

Para acessar posições de uma lista, usamos colchetes. Mas há uma diferença importante entre um par e dois pares de colchetes.

Observe:

```{r sublista}
tabelas_pagina[1]
class(tabelas_pagina[1])
```

Com `[1]`, obtemos uma **sublista** que contém o primeiro elemento. Ela continua sendo uma lista, mesmo que tenha apenas uma posição.

Agora faça:

```{r elemento-da-lista}
class(tabelas_pagina[[1]])
```

Com `[[1]]`, extraímos o **próprio objeto** guardado na primeira posição.

Uma maneira de pensar nessa diferença é imaginar uma caixa com várias tabelas. Usar `[1]` é pegar uma caixa menor contendo a primeira tabela. Usar `[[1]]` é retirar a tabela de dentro da caixa.

No nosso exemplo, queremos trabalhar com a tabela, não com a caixa que a contém.

# Escolhendo a tabela dos parques

Vamos começar pela primeira posição da lista. Guardaremos esse número em um objeto para deixar nossa escolha explícita:

```{r escolher-posicao}
posicao_tabela <- 1
```

Agora extraímos o elemento dessa posição:

```{r extrair-tabela-parques}
tabelas_parques <- tabelas_pagina[[posicao_tabela]]
```

Vamos conferir se encontramos o que procurávamos:

```{r conferir-tabela}
names(tabelas_parques)
head(tabelas_parques)
```

Compare os nomes das colunas e as primeiras linhas com a tabela que está aberta no navegador. Estamos vendo os nomes e as características dos parques?

**Não avance sem fazer essa conferência.** O número `1` não significa “tabela de parques nacionais”. Significa apenas “primeira tabela encontrada”. Se a organização da página mudar, pode ser necessário escolher outra posição.

Para examinar outra tabela, basta alterar `posicao_tabela` e executar novamente a extração. A função `length(tabelas_pagina)` informa quantas posições estão disponíveis.

Esse cuidado vale para outras pesquisas também. A raspagem de dados tem sempre um caráter um pouco artesanal: precisamos conhecer a página da qual estamos retirando as informações.

# Examinando os dados capturados

Agora podemos utilizar as funções de inspeção que já conhecemos:

```{r estrutura-dos-dados}
glimpse(tabelas_parques)
```

A tabela pode aparecer como uma *tibble*, que também é um data frame. Não é uma nova barreira: podemos trabalhar com ela usando as funções do *dplyr*.

Vamos verificar suas dimensões:

```{r dimensoes-dos-dados}
nrow(tabelas_parques)
ncol(tabelas_parques)
```

`nrow()` informa o número de linhas; `ncol()`, o número de colunas. Não precisamos colocar uma quantidade fixa de parques no código. A tabela pode ser atualizada, e nosso trabalho é observar o que foi capturado.

Também podemos olhar o começo e o final:

```{r primeiras-e-ultimas-linhas}
head(tabelas_parques)
tail(tabelas_parques)
```

No RStudio, podemos abrir o objeto em uma janela semelhante a uma planilha:

```{r visualizar-dados, eval=FALSE}
View(tabelas_parques)
```

Simples, não? Com poucas linhas, acessamos uma página de internet, extraímos suas tabelas e escolhemos aquela que nos interessa.

## Capturar não é o mesmo que tratar os dados

Observe os valores com atenção. Uma área pode ter sido capturada junto de sua unidade de medida. Uma data pode continuar sendo texto. Números de notas de referência podem aparecer ao lado das informações.

Isso não significa necessariamente que a raspagem falhou. Significa que a página foi escrita para leitura no navegador, e não para funcionar diretamente como uma base de dados pronta para análise.

Também não estamos baixando os arquivos de imagem que aparecem na tabela. A extração de uma tabela não equivale a guardar todos os seus elementos visuais.

Por enquanto, nossa tarefa termina aqui. Em uma pesquisa, o passo seguinte seria definir como tratar cada variável, preservando uma cópia dos dados tal como foram capturados.

# Código completo

Vamos juntar o código da atividade, sem as explicações, para observar como ele é curto:

```{r codigo-completo, eval=FALSE}
library(rvest)
library(tidyverse)

url_lista_parques <- "https://pt.wikipedia.org/wiki/Lista_de_parques_nacionais_do_Brasil"

pagina_lista_parques <- read_html(url_lista_parques)

tabelas_pagina <- pagina_lista_parques %>%
  html_table()

length(tabelas_pagina)

tabelas_parques <- tabelas_pagina[[1]]

names(tabelas_parques)
head(tabelas_parques)
glimpse(tabelas_parques)
```

Pronto! Já temos nossa primeira captura.

Mas pense no seguinte: os nomes dos parques, na página, são links. Clicar em um nome nos leva a outra página, com um texto sobre aquele parque. Onde estão os endereços desses links? E como poderíamos capturar os textos?

Para responder, precisaremos olhar não apenas para a tabela, mas para a **estrutura do HTML**. Esse será o assunto do próximo tutorial.
