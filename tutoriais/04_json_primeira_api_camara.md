---
title: "Tutorial 4 — Do HTML ao JSON: nossa primeira consulta à API da Câmara dos Deputados"
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

Nas atividades anteriores, aprendemos a capturar páginas da Wikipedia e a utilizar sua estrutura HTML para encontrar tabelas, links e parágrafos. Também vimos que documentos XML organizam informações por meio de elementos que podem conter outros elementos.

Mas imagine que queremos estudar os projetos de lei apresentados à Câmara dos Deputados. Nosso objetivo é construir um banco de dados com a identificação dos projetos, suas ementas e, mais adiante, seus textos completos. Será que precisamos entrar na página de cada projeto, encontrar as tags HTML correspondentes e fazer uma raspagem de dados?

Podemos fazer isso em alguns sites. Entretanto, a Câmara oferece um caminho mais simples: uma **API de Dados Abertos**, que permite consultar informações já organizadas para serem utilizadas por programas.

Antes de aprender a usar essa API, precisamos conhecer outro formato de organização dos dados: o **JSON**. Vamos partir dos mesmos parques, estados e trilhas que utilizamos no Tutorial 2 para compreender suas semelhanças e diferenças em relação ao XML.

Nesta atividade vamos fazer quatro coisas:

1. Conhecer a estrutura de um JSON e compará-la com a de um XML.
2. Entender o que é uma API, um *endpoint* e uma requisição.
3. Consultar a API da Câmara para obter uma pequena lista de Projetos de Lei (PLs) de 2025.
4. Utilizar o identificador de um dos projetos para consultar informações mais detalhadas sobre ele.

Vamos trabalhar com **apenas cinco projetos**. Nossa intenção é compreender o processo, e não coletar toda a produção legislativa nesta primeira atividade. No tutorial seguinte, ampliaremos a coleta, buscaremos os endereços dos documentos de inteiro teor e construiremos um corpus de textos legislativos.

# JSON: outra maneira de organizar dados

Lembra do nosso exemplo sobre os parques nacionais? No Tutorial 2, utilizamos XML para representar os estados e as trilhas de Itatiaia e da Tijuca. Vamos recuperar apenas o trecho correspondente a Itatiaia:

```xml
<parque>
  <nome>Itatiaia</nome>
  <estados>
    <estado>Minas Gerais</estado>
    <estado>Rio de Janeiro</estado>
  </estados>
  <trilhas>
    <trilha>
      <nome>Trilha do Mirante</nome>
      <extensao_km>3.2</extensao_km>
      <dificuldade>Fácil</dificuldade>
    </trilha>
    <trilha>
      <nome>Trilha da Cachoeira</nome>
      <extensao_km>5.0</extensao_km>
      <dificuldade>Moderada</dificuldade>
    </trilha>
  </trilhas>
</parque>
```

Já aprendemos a reconhecer essa estrutura: o elemento `parque` contém um nome, um conjunto de estados e um conjunto de trilhas. Cada trilha, por sua vez, tem seu próprio nome, sua extensão e sua dificuldade.

Podemos representar **exatamente essas mesmas informações** de outra maneira:

```json
{
  "nome": "Itatiaia",
  "estados": ["Minas Gerais", "Rio de Janeiro"],
  "trilhas": [
    {
      "nome": "Trilha do Mirante",
      "extensao_km": 3.2,
      "dificuldade": "Fácil"
    },
    {
      "nome": "Trilha da Cachoeira",
      "extensao_km": 5.0,
      "dificuldade": "Moderada"
    }
  ]
}
```

Este segundo documento está escrito em **JSON**, abreviação de *JavaScript Object Notation*. Embora o nome faça referência à linguagem JavaScript, o JSON é um formato de troca de dados que pode ser utilizado por várias linguagens, inclusive R.

Onde foram parar as tags? No JSON, não usamos uma tag de abertura e outra de fechamento para cada informação. Utilizamos **nomes associados a valores**, separados por dois pontos (`:`).

Observe que a hierarquia continua presente. As duas trilhas pertencem ao parque, e as características de cada trilha continuam juntas. O que mudou foi a maneira de escrever e organizar o documento.

## Chaves, colchetes e pares nome-valor

Vamos observar os símbolos com calma.

As **chaves**, `{` e `}`, envolvem um **objeto JSON**. Dentro dele encontramos pares formados por um nome e um valor:

```json
{
  "nome": "Itatiaia",
  "estados": ["Minas Gerais", "Rio de Janeiro"]
}
```

O nome da informação aparece entre **aspas duplas**. Depois vêm os dois pontos e seu valor. Uma vírgula separa um par do seguinte.

Os **colchetes**, `[` e `]`, representam um **array**, isto é, uma sequência de valores. No exemplo dos parques, usamos um array para os estados:

```json
["Minas Gerais", "Rio de Janeiro"]
```

Mas um array não precisa conter apenas textos. Ele também pode conter **objetos**. Foi isso que fizemos com `"trilhas"`: cada trilha é um objeto, e o conjunto de trilhas é um array.

E se quiséssemos reunir Itatiaia e Tijuca em um único JSON? Poderíamos criar um array de parques. Para simplificar este pequeno exemplo, vamos mostrar apenas os nomes e os estados:

```json
{
  "parques": [
    {
      "nome": "Itatiaia",
      "estados": ["Minas Gerais", "Rio de Janeiro"]
    },
    {
      "nome": "Tijuca",
      "estados": ["Rio de Janeiro"]
    }
  ]
}
```

Avance devagar. O valor associado a `"parques"` é um array. Esse array contém **dois objetos**. E cada objeto contém, por sua vez, um nome e um array de estados. No XML, utilizamos o elemento `parques` para reunir os diferentes parques; no JSON, usamos o nome `"parques"` associado ao array.

É parecido com o que fizemos no XML, não? Podemos guardar várias observações dentro de uma mesma estrutura, sem precisar representá-las desde o início como linhas de uma tabela.

## Textos, números, valores lógicos e informações ausentes

Os valores de um JSON não precisam ser sempre textos. Imagine que acrescentamos algumas informações demonstrativas à nossa trilha fictícia:

```json
{
  "nome": "Trilha do Mirante",
  "extensao_km": 3.2,
  "exemplo_didatico": true,
  "observacao": null
}
```

Temos diferentes tipos de valores:

- `"Trilha do Mirante"` é um **texto**, porque está entre aspas duplas.
- `3.2` é um **número**, escrito sem aspas. No JSON, o separador decimal é o ponto.
- `true` é um **valor lógico**. O outro valor lógico possível é `false`.
- `null` indica que não há um valor associado àquela informação.

Note que `true`, `false` e `null` são escritos em letras minúsculas e **sem aspas**. Os nomes e os textos de um JSON utilizam aspas **duplas**, não aspas simples.

Também não devemos confundir `null` com o texto `"null"`: o segundo seria apenas uma palavra. Quando convertermos o JSON para R, veremos que `null` pode ser representado por `NULL`. Isso não é automaticamente a mesma coisa que um `NA` dentro de um data frame.

Outra regra simples: o último par de um objeto não deve terminar em vírgula. O mesmo vale para o último elemento de um array.

# Lendo um JSON em R

Vamos fazer um pequeno experimento antes de visitar a API da Câmara.

Precisamos instalar dois pacotes que não utilizamos nas atividades anteriores: *jsonlite*, para trabalhar com JSON, e *httr2*, para fazer requisições a APIs. Também utilizaremos o *tidyverse*, que já conhecemos.

A instalação precisa ser feita apenas uma vez em cada computador:

```{r instalar-pacotes, eval=FALSE}
install.packages("jsonlite")
install.packages("httr2")
install.packages("tidyverse")
```

Em cada nova sessão, porém, precisamos chamar os pacotes:

```{r carregar-pacotes}
library(jsonlite)
library(httr2)
library(tidyverse)
```

Vamos guardar o JSON de Itatiaia em um objeto de texto. Repare nas aspas **simples** que utilizamos para delimitar esse texto em R. Assim, as aspas duplas do JSON podem ser mantidas sem alterações:

```{r exemplo-json-r}
exemplo_json <- '{
  "nome": "Itatiaia",
  "estados": ["Minas Gerais", "Rio de Janeiro"],
  "trilhas": [
    {"nome": "Trilha do Mirante", "extensao_km": 3.2, "dificuldade": "Fácil"},
    {"nome": "Trilha da Cachoeira", "extensao_km": 5.0, "dificuldade": "Moderada"}
  ],
  "exemplo_didatico": true,
  "observacao": null
}'
```

Até agora, `exemplo_json` é apenas um objeto da classe `character`. É como quando guardamos uma URL em um objeto: temos o texto, mas ainda não interpretamos sua estrutura.

Para transformar o texto JSON em objetos em R, vamos utilizar `fromJSON()`, do pacote *jsonlite*:

```{r converter-json}
dados_parque <- fromJSON(exemplo_json)

class(dados_parque)
str(dados_parque)
```

O resultado é uma **lista**. Lembra da diferença entre listas e data frames que estudamos no Tutorial 1? Aqui, a lista contém valores de diferentes tipos. Os nomes do JSON se tornaram os nomes dos elementos dessa lista.

Vamos acessar alguns deles utilizando `$`:

```{r acessar-lista-json}
dados_parque$nome
dados_parque$estados
dados_parque$trilhas
dados_parque$exemplo_didatico
is.null(dados_parque$observacao)
```

Observe o resultado de `dados_parque$trilhas`. Como cada trilha tem as mesmas informações, `fromJSON()` conseguiu transformar aquele array de objetos em um **data frame**! Temos duas linhas, uma para cada trilha, e colunas para suas características.

Esse é exatamente o raciocínio que fizemos no Tutorial 2, quando transformamos os elementos `trilha` em linhas de uma tabela. Naquele exemplo, tínhamos cinco trilhas distribuídas entre dois parques. Aqui, estamos trabalhando apenas com as duas trilhas de Itatiaia.

Vamos acrescentar a identificação do parque à tabela com as operações do *dplyr* que já conhecemos:

```{r criar-tabela-trilhas}
tabela_trilhas <- dados_parque$trilhas %>%
  as_tibble() %>%
  mutate(nome_parque = dados_parque$nome)

tabela_trilhas
```

Agora cada linha identifica uma trilha, suas características e o parque ao qual pertence. **Obs.:** não estamos extraindo informações da internet nesta etapa; o JSON foi escrito por nós para praticar.

Observe ainda que `true` se transforma em `TRUE` em R e que `null` pode ser recuperado como `NULL`, o que verificamos com `is.null()`.

Pronto! Já sabemos algo importante: **um JSON não é necessariamente uma tabela**. Ele pode representar listas, vetores e estruturas dentro de outras estruturas. Nossa tarefa é examinar o que recebemos e identificar a unidade de observação que interessa à pesquisa.

**Exercício:** acrescente uma terceira trilha ao array `"trilhas"` de `exemplo_json`. Execute novamente os blocos que utilizam `fromJSON()` e constroem `tabela_trilhas`. Quantas linhas temos agora? Depois, coloque o valor de uma das extensões entre aspas, como se fosse um texto. O que acontece com o tipo da coluna `extensao_km`?

# O que é uma API?

Voltemos ao nosso problema com as proposições legislativas.

Quando visitamos a Wikipedia, o servidor nos entrega uma página HTML que o navegador organiza para leitura. Para obtermos os dados, precisamos reconhecer as tabelas, os links e os parágrafos daquela página.

Uma **API** (*Application Programming Interface*, ou Interface de Programação de Aplicações) é uma maneira definida de permitir que um programa se comunique com outro programa ou serviço. No nosso caso, a API da Câmara dos Deputados permite que façamos perguntas a um servidor e recebamos informações em um formato que conseguimos interpretar em R.

Isso significa que não precisamos procurar a ementa de um projeto dentro das tags de uma página. Podemos solicitar diretamente os dados organizados sobre aquele projeto.

Há vários tipos de API. Nesta atividade utilizaremos uma **API Web**, acessada por endereços da internet. E vamos fazer apenas consultas: **pediremos informações**, sem enviar mudanças para o banco de dados da Câmara.

## Conhecendo a documentação da Câmara

Antes de programar, visite a [página da API de Dados Abertos da Câmara dos Deputados](https://dadosabertos.camara.leg.br/swagger/api.html?tab=api).

Procure a parte chamada **Proposições**. Ali estão descritas, entre outras, duas operações que vamos utilizar:

- `GET /proposicoes`: obter uma lista de proposições, com a possibilidade de aplicar filtros.
- `GET /proposicoes/{id}`: obter as informações detalhadas de uma proposição específica.

O `GET` indica que estamos fazendo uma requisição para **consultar** informações. É o mesmo método utilizado pelo navegador na maioria das visitas a páginas da internet.

Cada um desses caminhos é chamado de **endpoint**. Pense no endpoint como uma porta de entrada para determinado conjunto de informações. Um endpoint pode listar projetos; outro pode trazer os detalhes de um projeto; outros podem oferecer autores, tramitações ou votações.

E o que significa `{id}`? É um espaço reservado para o identificador de uma proposição. Quando fizermos uma consulta real, substituiremos `{id}` pelo número identificador do projeto que queremos examinar.

Não precisamos decorar esses caminhos. Uma boa parte do trabalho com APIs consiste justamente em **consultar sua documentação** para descobrir quais informações estão disponíveis, como pedi-las e como interpretar o resultado.

## Endereço, endpoint e parâmetros

Nossa primeira consulta será feita neste endereço:

```text
https://dadosabertos.camara.leg.br/api/v2/proposicoes
```

Ele contém o endereço do servidor e o caminho que identifica a lista de proposições.

Entretanto, queremos apenas **Projetos de Lei de 2025**, e não todas as proposições. Além disso, queremos começar com cinco registros. Podemos informar isso acrescentando **parâmetros** à URL:

```text
https://dadosabertos.camara.leg.br/api/v2/proposicoes?siglaTipo=PL&ano=2025&itens=5
```

Vamos ler o pedaço acrescentado ao final da URL:

- O ponto de interrogação `?` marca o início dos parâmetros.
- `siglaTipo=PL` informa que queremos proposições cuja sigla do tipo seja `PL`.
- `ano=2025` restringe a consulta ao ano de apresentação de 2025.
- `itens=5` pede cinco registros na página de resultados.
- O símbolo `&` separa os parâmetros uns dos outros.

Esses parâmetros são chamados de **parâmetros de consulta**, ou *query parameters*. Eles não são caminhos XPath nem seletores CSS: **não procuram elementos dentro de um HTML**. São instruções enviadas ao servidor para que ele decida quais dados devolver.

Abra o endereço completo no navegador. Dependendo do navegador, você verá diretamente um JSON ou uma apresentação formatada dele. Alguns navegadores possuem extensões para organizar a visualização de JSON.

Observe principalmente os nomes `"dados"` e `"links"`, que aparecem na estrutura da resposta. Vamos encontrá-los daqui a pouco em  R.

**Obs.:** a URL pede cinco registros, não necessariamente todos os PLs que existem em 2025. Essa diferença será fundamental no tutorial seguinte.

# Nossa primeira consulta à API no R

Vamos fazer em R a mesma consulta que acabamos de experimentar no navegador. Usaremos o pacote *httr2*, que organiza uma requisição em etapas.

Primeiro, guardamos o endereço básico e criamos um objeto de requisição com `request()`:

```{r criar-requisicao}
url_proposicoes <- "https://dadosabertos.camara.leg.br/api/v2/proposicoes"

req <- request(url_proposicoes)

req
```

**Atenção:** criar uma requisição **não significa executá-la**. Até aqui, preparamos um objeto que informa aonde queremos ir, mas ainda não pedimos os dados ao servidor.

Isso lembra a diferença que vimos entre criar um objeto com o endereço da Wikipedia e utilizar `read_html()` para efetivamente acessar a página.

## Informando o formato e os filtros

Vamos acrescentar as informações que faltam. Utilizaremos `req_headers()` para indicar que desejamos receber JSON e `req_url_query()` para colocar os parâmetros na URL:

```{r preparar-requisicao}
req <- req %>%
  req_headers(Accept = "application/json") %>%
  req_url_query(
    siglaTipo = "PL",
    ano = 2025,
    ordem = "ASC",
    ordenarPor = "id",
    itens = 5
  )

req
```

Vamos ler o código:

1. Partimos do objeto `req`, que criamos com `request()`.
2. `req_headers(Accept = "application/json")` acrescenta uma informação ao **cabeçalho da requisição**: estamos solicitando uma resposta no formato JSON.
3. `req_url_query()` acrescenta os parâmetros. Além dos filtros já vistos, pedimos uma ordenação crescente (`ASC`) pelo identificador (`id`).
4. Guardamos a requisição preparada novamente em `req`.

O *header* não é o cabeçalho de uma tabela e tampouco a tag `head` do HTML. É um conjunto de informações que acompanha a comunicação entre nosso computador e o servidor. Nesta atividade, só precisamos do cabeçalho `Accept`.

Observe também que continuamos utilizando o *pipe* `%>%`, o mesmo que aprendemos nas atividades anteriores. Passamos a requisição de uma função para a seguinte, assim como fazemos quando manipulamos data frames com o *dplyr*.

## Executando a requisição

Agora sim vamos nos comunicar com o servidor:

```{r executar-requisicao}
resp <- req_perform(req)

resp_status(resp)
```

A função `req_perform()` realiza a requisição e guarda a **resposta** no objeto `resp`.

`resp_status()` mostra o código de resposta HTTP. Um resultado `200` indica que a requisição foi atendida com sucesso. Existem outros códigos: por exemplo, `404` indica que um recurso solicitado não foi encontrado, e `429` costuma indicar excesso de requisições em determinado intervalo.

Se a conexão falhar, o servidor estiver indisponível ou os parâmetros forem inválidos, a requisição pode produzir um erro. Isso não significa necessariamente que o código em R esteja errado: estamos dependendo também de um serviço externo.

**Importante:** `resp` ainda não é um *data frame*. É um objeto que contém a resposta HTTP, incluindo informações sobre a resposta e seu conteúdo.

# Da resposta JSON ao data frame

Para extrair e interpretar o corpo da resposta, utilizaremos `resp_body_json()`. O argumento `simplifyVector = TRUE` permite converter automaticamente estruturas regulares — como uma lista de registros com as mesmas variáveis — em *data frames*, quando isso é possível.

```{r interpretar-resposta}
corpo <- resp_body_json(resp, simplifyVector = TRUE)

class(corpo)
names(corpo)
```

O resultado é uma lista. Na resposta da API, dois elementos serão especialmente importantes para nós: `dados` e `links`.

O elemento `dados` contém as proposições pedidas. O elemento `links` contém endereços relacionados à consulta, inclusive informações que podem ajudar a navegar pelas páginas de resultados.

Vamos acessar o primeiro:

```{r examinar-dados-api}
class(corpo$dados)
names(corpo$dados)
head(corpo$dados)
```

Repare no uso de `$`: é exatamente a mesma operação que praticamos com o JSON do parque nacional. Antes estávamos acessando `dados_parque$nome`; agora acessamos `corpo$dados`.

Como os registros de proposições possuem uma estrutura tabular, a função já conseguiu representar `dados` como um *data frame*. Vamos guardá-lo como um `tibble`, nosso formato habitual de trabalho:

```{r criar-dataframe-proposicoes}
df_proposicoes_simples <- as_tibble(corpo$dados)

glimpse(df_proposicoes_simples)
```

Pronto! Acabamos de transformar a resposta da API em um conjunto de dados que podemos manipular com o *dplyr*.

Vamos escolher algumas colunas que nos interessam:

```{r selecionar-colunas-pl}
df_proposicoes_simples %>%
  select(id, siglaTipo, numero, ano, ementa)
```

Observe a coluna `ementa`: temos uma descrição do conteúdo da proposição, sem precisar entrar em uma página HTML e procurar seus parágrafos.

Se estiver utilizando o RStudio, você pode examinar o conjunto de dados em uma janela semelhante a uma planilha:

```{r abrir-tabela-proposicoes, eval=FALSE}
View(df_proposicoes_simples)
```

**Exercício:** utilize `filter()` para selecionar uma das proposições pelo valor da coluna `id`. Depois experimente `select()` para mostrar apenas `numero`, `ano` e `ementa`. Essas são operações do *dplyr* que já conhecemos: a novidade desta aula está em **como obtivemos os dados**, não na manipulação da tabela.

## E os links que vieram no JSON?

Vamos examinar a outra parte da resposta:

```{r examinar-links-api}
corpo$links
```

Você encontrará relações identificadas por palavras como `self`, `first`, `next` ou `last`, dependendo da consulta e da quantidade de páginas disponíveis. Esses links permitem saber, por exemplo, qual é o endereço da próxima página de resultados.

Você pode encontrar a palavra `href` nesses objetos. Lembra do `href` que estudamos no HTML? Lá, ele era um **atributo** de uma tag `a`. Aqui, `href` é o **nome de uma informação do JSON** cujo valor é uma URL. O endereço pode cumprir uma função semelhante, mas a maneira de representá-lo é diferente.

Por que isso importa? Porque nossa consulta pediu somente cinco registros. A API pode ter milhares de proposições para devolver, e normalmente não enviará todas de uma só vez. Ela divide os resultados em **páginas**.

Observe como este problema se parece com uma situação que já conhecemos: quando raspamos resultados distribuídos em várias páginas de um site, precisamos visitar cada uma delas para reunir todos os registros. No tutorial seguinte utilizaremos essa ideia para coletar um conjunto maior de proposições.

Por enquanto, vamos ficar com os cinco registros. Precisamos aprender mais uma operação antes de encerrar.

# Obtendo os detalhes de uma proposição

Nossa primeira tabela contém uma coluna chamada `id`. Esse identificador é importante porque a API pode utilizá-lo para localizar uma proposição específica.

**Não confunda** o `id` da API com o número do projeto. Uma proposição pode ser conhecida como *PL número X de 2025*, mas possui também um identificador numérico próprio no serviço de dados.

Vamos recuperar os identificadores com `pull()`, como fizemos com os endereços dos parques no Tutorial 3. Depois escolhemos o primeiro elemento do vetor:

```{r escolher-id}
ids_proposicoes <- df_proposicoes_simples %>%
  pull(id)

id_proposicao <- ids_proposicoes[1]

id_proposicao
```

`pull(id)` extrai a coluna `id` do data frame, e `[1]` escolhe seu primeiro elemento. Já quando escrevemos `corpo$dados` ou `proposicao$ementa`, estamos acessando informações de **listas**, como fizemos com `dados_parque$nome`.

Agora vamos visitar outro endpoint: `/proposicoes/{id}`. Utilizaremos a função `paste0()`, que já conhecemos, para colocar o identificador ao final do endereço:

```{r criar-url-detalhe}
url_detalhe <- paste0(
  "https://dadosabertos.camara.leg.br/api/v2/proposicoes/",
  id_proposicao
)

url_detalhe
```

Se você copiar o valor de `url_detalhe` para o navegador, verá que não estamos mais pedindo uma lista. Estamos pedindo **uma proposição específica**.

Vamos repetir a operação no R:

```{r consultar-detalhe}
req_detalhe <- request(url_detalhe) %>%
  req_headers(Accept = "application/json")

resp_detalhe <- req_perform(req_detalhe)

corpo_detalhe <- resp_body_json(resp_detalhe, simplifyVector = TRUE)

names(corpo_detalhe)
```

Até aqui, nenhuma função nova! Apenas mudamos o endereço da consulta.

Também aqui as informações principais estão dentro de `dados`. Vamos extraí-las:

```{r examinar-detalhe}
proposicao <- corpo_detalhe$dados

class(proposicao)
names(proposicao)
```

Observe a diferença. Na primeira consulta, `dados` continha **várias proposições**, que conseguimos organizar em linhas de um *data frame*. Agora contém **uma proposição**, com diferentes campos e, possivelmente, estruturas dentro de outras estruturas. É comum que esse resultado seja uma lista.

Podemos acessar diretamente algumas informações:

```{r campos-do-detalhe}
proposicao$id
proposicao$ementa
proposicao$dataApresentacao
proposicao$urlInteiroTeor
```

O último campo merece atenção especial. Quando está disponível, `urlInteiroTeor` informa o endereço do documento que contém o texto da proposição.

Ainda não vamos baixar esse arquivo. Por enquanto, queremos apenas reconhecer que uma API pode oferecer **metadados** — informações que descrevem um documento — e também o endereço de um arquivo que poderemos consultar posteriormente.

**Obs.:** nem toda proposição terá necessariamente um endereço de inteiro teor disponível. E não devemos presumir que todo endereço retorne um PDF válido. No tutorial seguinte precisaremos conferir os arquivos antes de tratá-los como documentos de um corpus.

Excelente! Com apenas duas consultas, recuperamos uma pequena tabela de proposições e, usando o `id`, obtivemos informações detalhadas de um dos projetos.

# Uma observação sobre a paginação

Vamos fazer mais um pequeno experimento, sem construir nenhum loop.

No endpoint que retorna a lista de proposições, podemos incluir o parâmetro `pagina`. Veja como pedir a segunda página, mantendo os filtros que já utilizamos:

```{r segunda-pagina, eval=FALSE}
req_pagina2 <- req %>%
  req_url_query(pagina = 2)

resp_pagina2 <- req_perform(req_pagina2)

corpo_pagina2 <- resp_body_json(resp_pagina2, simplifyVector = TRUE)

df_pagina2 <- as_tibble(corpo_pagina2$dados)

head(df_pagina2)
```

Por que deixamos esse bloco para execução manual? Porque ele é um exercício adicional. A coleta que fizemos até aqui já está completa.

Experimente executá-lo no RStudio e compare os identificadores da primeira e da segunda páginas. Você deverá encontrar registros diferentes.

E se quisermos a terceira, quarta ou centésima página? Já aprendemos a utilizar **for loops** para repetir operações. No próximo tutorial, vamos combinar essa técnica com as consultas à API.

# Código completo da atividade

Vamos juntar o essencial do nosso exemplo, sem as explicações e sem o JSON didático dos parques. O código necessário para obter cinco proposições e consultar os detalhes da primeira delas é bastante curto:

```{r codigo-completo, eval=FALSE}
library(httr2)
library(tidyverse)

req <- request("https://dadosabertos.camara.leg.br/api/v2/proposicoes") %>%
  req_headers(Accept = "application/json") %>%
  req_url_query(
    siglaTipo = "PL",
    ano = 2025,
    ordem = "ASC",
    ordenarPor = "id",
    itens = 5
  )

resp <- req_perform(req)
corpo <- resp_body_json(resp, simplifyVector = TRUE)

df_proposicoes_simples <- as_tibble(corpo$dados)

glimpse(df_proposicoes_simples)

ids_proposicoes <- df_proposicoes_simples %>%
  pull(id)

id_proposicao <- ids_proposicoes[1]

url_detalhe <- paste0(
  "https://dadosabertos.camara.leg.br/api/v2/proposicoes/",
  id_proposicao
)

req_detalhe <- request(url_detalhe) %>%
  req_headers(Accept = "application/json")

resp_detalhe <- req_perform(req_detalhe)
proposicao <- resp_body_json(resp_detalhe, simplifyVector = TRUE)$dados

proposicao$ementa
proposicao$urlInteiroTeor
```

Compare com o que fizemos nas aulas sobre raspagem de páginas. Antes, precisávamos selecionar elementos HTML e extrair seus textos ou atributos. Agora, os nomes das informações já estão definidos no JSON, e podemos acessá-las diretamente depois de interpretar a resposta.

Isso não significa que uma API seja sempre mais fácil ou que todos os sites tenham uma API pública. Significa apenas que, **quando um serviço oferece dados organizados e documentados, vale a pena conhecer essa possibilidade antes de construir uma raspagem de HTML**.

# Referências para consulta

- [API de Dados Abertos da Câmara dos Deputados — documentação interativa](https://dadosabertos.camara.leg.br/swagger/api.html?tab=api). Procure a seção **Proposições** e os endpoints `GET /proposicoes` e `GET /proposicoes/{id}`.
- [JSON — introdução e estrutura do formato](https://www.json.org/json-en.html). Apresenta objetos, arrays e os tipos de valores admitidos.

