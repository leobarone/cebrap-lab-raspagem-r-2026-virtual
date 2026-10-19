---
title: "Tutorial 0 — Primeiros passos no R: manipulando dados com dplyr"
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

# Apresentação

Um dos aspectos mais interessantes da linguagem R é a possibilidade de ampliar suas funcionalidades com pacotes desenvolvidos pela comunidade de usuárias e usuários. Ao longo do tempo, surgiram diferentes formas de importar, organizar e analisar bases de dados.

Uma das mais utilizadas é a do pacote *dplyr*, parte do *tidyverse*. Seus comandos costumam ser chamados de **verbos**, porque representam operações como selecionar, filtrar, transformar e resumir informações.

Também podemos realizar essas tarefas utilizando as funções que já vêm com o R, frequentemente chamadas de funções do *R base*. Não são linguagens diferentes: são maneiras diferentes de resolver problemas no mesmo ambiente.

Este é nosso **Tutorial 0**, uma atividade de revisão dos conhecimentos que utilizaremos nos próximos tutoriais sobre raspagem de páginas, APIs e construção de coleções de textos. Vamos começar por um cadastro real de escolas, disponível na internet, e utilizá-lo para praticar a manipulação de dados.

Ao final, você deverá conseguir importar um arquivo CSV, examinar um *data frame* e usar `rename()`, `select()`, `mutate()`, `filter()` e o operador `%>%`. Retomaremos também a criação de objetos, os argumentos das funções e a extração de uma coluna com `pull()`.

# Instalando e carregando pacotes

Quando abrimos o R ou o RStudio, algumas funções já estão disponíveis. Outras precisam ser instaladas por meio de **pacotes**.

**Instalar** e **carregar** são coisas diferentes. Instalamos um pacote uma vez em nosso computador; carregamos o pacote a cada nova sessão em que pretendemos utilizá-lo.

Se você ainda não tem o *tidyverse*, execute **uma vez**, no console do R:

```{r instalar-pacote, eval=FALSE}
install.packages("tidyverse")
```

Depois, carregue o pacote:

```{r carregar-pacotes}
library(tidyverse)
```

O *tidyverse* é um conjunto de pacotes que inclui, entre outros, o *dplyr* (manipulação de dados), o *readr* (leitura e escrita de arquivos) e o *ggplot2* (visualização de dados). Nesta atividade, nosso foco será a manipulação de tabelas.

**Obs.:** evitamos executar `install.packages()` automaticamente ao gerar o HTML com **Knit**, pois uma instalação depende do computador e da conexão com a internet. Faça-a no console quando necessário.

# Começando pelo meio: data frames

Uma característica importante do R é sua utilização na análise de dados. E, quando pensamos em análise, uma das protagonistas é a **base de dados**, representada frequentemente por um *data frame*.

Em um *data frame*, cada **linha** representa uma observação e cada **coluna** representa uma variável. Por exemplo, imagine esta pequena tabela fictícia:

| Candidato | Partido | Votos |
|:---|:---|---:|
| Beatriz | MDB | 350 |
| Danilo | PSOL | 1598 |
| Pedro | PTB | 784 |
| Davi | PSD | 580 |
| Mateus | PV | 2 |

Cada linha representa uma candidatura. As colunas guardam informações diferentes sobre ela. `Candidato` e `Partido` contêm textos; `Votos`, números.

Em R, os elementos de uma mesma coluna geralmente compartilham um tipo de dado: `character` para textos, `integer` ou `numeric` para números, `logical` para valores `TRUE` e `FALSE`, entre outros. Classificações como **nominal**, **ordinal** e **contínua**, que encontramos nos cursos de estatística, dizem respeito à natureza das variáveis; não são exatamente os tipos de objetos utilizados pelo R.

Se destacarmos a coluna de votos, teremos um **vetor** com os valores `350`, `1598`, `784`, `580` e `2`. Um *data frame* reúne várias colunas dessa maneira.

*Data frames* e vetores são **objetos** do R: informações guardadas na memória e identificadas por nomes. Vamos utilizá-los agora com um exemplo mais próximo da pesquisa com dados públicos.

# Cadastro de escolas

Trabalharemos com o **Cadastro de escolas municipais, conveniadas e privadas**, publicado pela Prefeitura de São Paulo no [Portal de Dados Abertos](https://dados.prefeitura.sp.gov.br/dataset/cadastro-de-escolas-municipais-conveniadas-e-privadas).

Nosso arquivo é uma edição do cadastro identificada como `escolas122024.csv`, referente a dezembro de 2024. Ele contém informações sobre as unidades escolares, como nome, tipo de escola, códigos de identificação e Diretoria Regional de Educação.

Antes de executar o código, visite a página do conjunto de dados e procure o arquivo e seu dicionário de variáveis. Em uma pesquisa, conhecer a origem dos dados e o significado das colunas é parte do trabalho.

## Abrindo dados diretamente da internet

Um arquivo CSV é um documento de texto que armazena informações em formato de tabela. Podemos abri-lo com uma função do R sem precisar baixá-lo manualmente para uma pasta.

Vamos guardar o endereço do arquivo em um objeto de texto e depois utilizá-lo para ler os dados:

```{r abrir-escolas}
url_escolas <- "https://dados.prefeitura.sp.gov.br/dataset/8da55b0e-b385-4b54-9296-d0000014ddd5/resource/533188c6-1949-4976-ac4e-acd313415cd1/download/escolas122024.csv"

escolas <- read_csv2(url_escolas, show_col_types = FALSE)
```

A função `read_csv2()`, do pacote *readr*, lê arquivos em que as colunas são separadas, por padrão, por **ponto e vírgula**. A função `read_csv()` espera, por padrão, colunas separadas por **vírgulas**. O argumento `show_col_types = FALSE` apenas esconde a mensagem que descreve os tipos de colunas reconhecidos.

Em R, o símbolo `<-` serve para **atribuição**: o resultado à direita é guardado em um objeto cujo nome aparece à esquerda. Criamos, assim, o objeto `escolas`, que agora contém os dados do cadastro.

Veja que `url_escolas` contém um endereço na internet, não o caminho de um arquivo no computador. Retomaremos essa distinção nos tutoriais de raspagem.

**Obs.:** estamos usando um endereço de um arquivo público. Se ele estiver temporariamente indisponível ou for alterado pela Prefeitura, será necessário consultar a página do conjunto de dados antes de continuar. O código desta atividade depende do acesso a esse arquivo real; não utilizaremos um conjunto de dados substituto.

## Conferindo os nomes das colunas

Arquivos publicados em momentos diferentes podem apresentar pequenas mudanças nos nomes das variáveis. Vamos conferir o cabeçalho:

```{r conferir-cabecalho-original}
names(escolas)
```

Para que os exemplos usem a mesma grafia, colocaremos os nomes das colunas em maiúsculas. Algumas edições do cadastro utilizam `NOMESC` para o nome da escola, e outras podem utilizar `NOMES`. Faremos essa pequena padronização, caso seja necessária:

```{r padronizar-cabecalho}
names(escolas) <- toupper(names(escolas))

if ("NOMESC" %in% names(escolas)) {
  escolas <- escolas %>%
    rename(NOMES = NOMESC)
}

names(escolas)
```

O `if` apenas verifica se a coluna `NOMESC` existe e, nesse caso, muda seu nome para `NOMES`. Ele não altera os registros das escolas. Não precisamos estudar agora os detalhes dessa condição: utilizaremos os demais comandos de manipulação com os nomes assim definidos.

Vamos também guardar a versão original da tabela em outro objeto, para podermos retomar as variáveis antes das transformações, **sem fazer outra solicitação ao servidor**:

```{r guardar-base-original}
escolas_originais <- escolas
```

Os dois objetos estão na memória do R. Não estamos criando uma cópia do CSV no computador.

# Conhecendo a base sem olhar todas as linhas

Podemos examinar a tabela inteira no RStudio com `View()`, mas isso não é necessário para conhecer sua estrutura. Se quiser, execute o comando a seguir no console:

```{r visualizar-tabela, eval=FALSE}
View(escolas)
```

A função `head()` mostra, por padrão, as seis primeiras linhas:

```{r primeiras-linhas}
head(escolas)
```

Quantas escolas há? Basta contar as linhas:

```{r dimensoes}
nrow(escolas)
ncol(escolas)
```

`nrow()` informa quantas linhas existem; `ncol()`, quantas colunas. E, para conhecer os nomes das variáveis:

```{r nomes-colunas}
names(escolas)
```

Também podemos examinar a estrutura do objeto:

```{r estrutura-dados}
class(escolas)
str(escolas)
glimpse(escolas)
```

`class()` informa a classe do objeto. `str()` apresenta sua estrutura e os tipos de variáveis. `glimpse()`, do *dplyr*, traz um resumo semelhante em um formato conveniente para *data frames*.

## Comentários e argumentos das funções

Podemos escrever comentários no código. Basta usar `#`; tudo o que vem depois dele, até o final da linha, é tratado como comentário:

```{r comentarios}
# Quais são os nomes das colunas?
names(escolas)

nrow(escolas) # Quantidade de linhas
```

Comentários são úteis para documentar o que fazemos, especialmente quando compartilhamos o código com outras pessoas ou voltamos a ele meses depois.

Observe também os parênteses das funções. Tudo o que colocamos dentro deles corresponde aos **argumentos** da função. Algumas funções recebem vários argumentos, e alguns possuem valores previamente definidos.

Por exemplo, para mostrar dez linhas em vez das seis que aparecem por padrão, escrevemos:

```{r argumentos-head}
head(x = escolas, n = 10)
```

`x` indica o objeto e `n` indica quantas linhas queremos ver. Podemos consultar a ajuda de uma função com `?head`, diretamente no console.

# Renomeando variáveis

Quando utilizamos dados que não produzimos, frequentemente encontramos nomes de variáveis pouco confortáveis para escrever códigos. Podemos preferir nomes curtos, sem espaços, em letras minúsculas e com `_` para separar palavras.

Veja os nomes das variáveis do cadastro:

```{r conferir-nomes-originais}
names(escolas)
```

Vamos começar renomeando três colunas:

```{r primeiro-rename}
escolas <- rename(escolas, tipo = TIPOESC, lat = LATITUDE, lon = LONGITUDE)

names(escolas)
```

A função `rename()` usa a ordem **nome_novo = nome_antigo**. O comando modifica os nomes no objeto `escolas` porque guardamos o resultado novamente nele, com `<-`.

## Uma gramática, duas formas

No *tidyverse*, podemos escrever a mesma operação com o operador `%>%`, chamado *pipe*. Antes, porém, vamos recuperar a versão inicial dos dados, pois as colunas `TIPOESC`, `LATITUDE` e `LONGITUDE` já foram renomeadas:

```{r reabrir-escolas}
escolas <- escolas_originais
```

Agora faremos uma renomeação mais completa:

```{r renomear-colunas}
escolas <- escolas %>%
  rename(
    dre_abreviatura = DRE,
    codigo = CODESC,
    tipo = TIPOESC,
    nome = NOMES,
    dre = DIRETORIA,
    lat = LATITUDE,
    lon = LONGITUDE,
    codigo_inep = CODINEP
  )

names(escolas)
```

Podemos ler: **pegue o objeto `escolas` e aplique a ele a função `rename()`**. O `%>%` passa o resultado de uma etapa para a seguinte.

Compare com `rename(escolas, ...)`, que escrevemos anteriormente. O resultado é o mesmo, mas o *pipe* permite colocar várias operações em sequência. Utilizaremos essa forma nos próximos tutoriais.

**Obs.:** o R também tem o operador nativo `|>`. Nesta oficina, manteremos `%>%`, como nos outros exemplos do curso.

# Selecionando colunas com `select()`

Nem sempre precisamos de todas as variáveis presentes na base. Podemos selecionar somente as que nos interessam:

```{r selecionar-colunas}
escolas <- escolas %>%
  select(dre_abreviatura, codigo, tipo, nome, dre, lat, lon, codigo_inep)

head(escolas)
```

Observe que `select()` escolhe **colunas**, não linhas.

## Encadeando operações com `%>%`

Uma das vantagens do *pipe* é poder ler o código como uma sequência de tarefas. Vamos refazer a renomeação e a seleção diretamente a partir do objeto com os dados originais:

```{r exemplo-encadeamento}
escolas <- escolas_originais %>%
  rename(
    dre_abreviatura = DRE,
    codigo = CODESC,
    tipo = TIPOESC,
    nome = NOMES,
    dre = DIRETORIA,
    lat = LATITUDE,
    lon = LONGITUDE,
    codigo_inep = CODINEP
  ) %>%
  select(dre_abreviatura, codigo, tipo, nome, dre, lat, lon, codigo_inep)
```

Começamos pelo *data frame* que recuperamos da internet. Em seguida, `rename()` altera os nomes de algumas colunas e `select()` escolhe quais devem permanecer. A primeira leitura, feita com `read_csv2(url_escolas)`, continua documentada no início da atividade.

**Exercício:** use `select()` para criar um novo objeto contendo apenas o nome, o tipo e a Diretoria Regional de Educação de cada escola. Confira seus nomes com `names()`.

# Transformando variáveis com `mutate()`

Usamos `mutate()` para modificar uma variável existente ou criar outra nova. Uma transformação pode envolver uma operação matemática, uma comparação ou uma expressão que produza textos.

Por exemplo, podemos criar uma coluna que informa a quantidade de caracteres dos nomes das escolas. A função `nchar()` faz essa contagem:

```{r criar-numero-caracteres}
escolas <- escolas %>%
  mutate(n_caracteres_nome = nchar(nome))

head(escolas)
```

Acrescentamos uma coluna ao cadastro sem modificar o conteúdo das anteriores. Como não atribuímos o resultado diretamente à coluna `nome`, ela continua disponível com os nomes das escolas.

Também podemos criar uma variável que indica se uma escola é do tipo EMEI, usando uma comparação:

```{r criar-nova-variavel}
escolas <- escolas %>%
  mutate(eh_emei = tipo == "EMEI")

head(escolas)
```

A nova coluna contém `TRUE` quando a condição é satisfeita e `FALSE` quando não é. Ela nos ajudará a compreender os filtros.

**Exercício:** use `mutate()` para criar uma coluna chamada `nome_com_tipo`, reunindo `tipo` e `nome` com a função `paste(tipo, nome)`.

# Filtrando linhas com `filter()`

Às vezes, queremos trabalhar somente com parte das observações. Por exemplo, podemos selecionar as Escolas Municipais de Educação Infantil (EMEI):

```{r filtrar-emeis}
emeis <- escolas %>%
  filter(tipo == "EMEI")

nrow(emeis)
head(emeis)
```

`filter()` seleciona **linhas** que satisfazem uma condição. O símbolo `==` significa igualdade; `!=` significa diferença; `>`, `<`, `>=` e `<=` permitem outras comparações. Para verificar valores ausentes (`NA`), usamos `is.na()`, não `== NA`.

## Combinando condições: OU e E

Vamos selecionar três tipos de centro de educação infantil:

```{r filtrar-creches}
creches <- escolas %>%
  filter(tipo == "CEI DIRET" |
         tipo == "CEI INDIR" |
         tipo == "CR.P.CONV")

nrow(creches)
```

A barra vertical `|` significa **OU**: basta que uma das condições seja verdadeira.

Agora, queremos essas mesmas categorias, mas **somente na Diretoria Regional de Educação do Ipiranga**. Precisamos utilizar **E**, representado por `&`:

```{r filtrar-creches-ipiranga}
creches_ipiranga <- escolas %>%
  filter(
    (tipo == "CEI DIRET" |
     tipo == "CEI INDIR" |
     tipo == "CR.P.CONV") &
    str_detect(dre, "IPIRANGA")
  )

nrow(creches_ipiranga)
```

**Preste atenção aos parênteses.** Sem eles, a condição sobre a Diretoria Regional poderia ser aplicada apenas à última alternativa, e não às três categorias de escolas. A função `str_detect()`, do *stringr*, identifica os registros cujo nome da Diretoria contém o texto `IPIRANGA`.

Podemos escrever a mesma seleção utilizando uma vírgula entre as condições do `filter()`. Dentro de `filter()`, a vírgula funciona como **E**:

```{r filtrar-com-virgula}
creches_ipiranga <- escolas %>%
  filter(
    tipo == "CEI DIRET" |
      tipo == "CEI INDIR" |
      tipo == "CR.P.CONV",
    str_detect(dre, "IPIRANGA")
  )
```

As duas versões devem selecionar as mesmas escolas:

```{r conferir-filtro}
nrow(creches_ipiranga)
head(creches_ipiranga)
```

# Contando e extraindo informações

Além de selecionar e modificar dados, podemos responder rapidamente a algumas perguntas sobre a tabela.

## Quantas escolas existem de cada tipo?

O verbo `count()` conta as observações de cada categoria:

```{r contar-tipos}
escolas %>%
  count(tipo, sort = TRUE)
```

`sort = TRUE` apresenta os tipos mais frequentes primeiro. É uma forma rápida de conhecer a distribuição de uma variável categórica.

## E se quisermos apenas os nomes das escolas?

Nos primeiros tutoriais de raspagem precisaremos transformar colunas de *data frames* em vetores. A função `pull()`, do *dplyr*, faz exatamente isso:

```{r extrair-vetor}
nomes_escolas <- escolas %>%
  pull(nome)

class(nomes_escolas)
head(nomes_escolas)
```

O resultado já não é um *data frame*, mas um vetor de textos. No Tutorial 3 faremos uma operação semelhante para reunir endereços de páginas da Wikipedia.

# Para praticar

**Primeiro exercício:** crie um objeto com apenas as escolas do tipo `EMEI` e apresente suas colunas `nome` e `dre`.

**Segundo exercício:** utilize `count()` para descobrir quantas escolas há em cada Diretoria Regional de Educação do cadastro.

**Terceiro exercício:** crie uma coluna chamada `nome_curto` contendo exatamente o mesmo texto da coluna `nome`. Qual é a diferença entre criar essa coluna com `mutate()` e renomear `nome` com `rename()`?

**Quarto exercício:** refaça o filtro de creches do Ipiranga e retire os parênteses do primeiro exemplo. Compare as quantidades encontradas e explique o que mudou. Essa comparação é apenas um exercício: **a versão correta é aquela em que as três categorias são combinadas antes da condição sobre a DRE**.

## Retomando a origem dos dados

Todo o exercício foi realizado com o cadastro real obtido diretamente da Prefeitura de São Paulo. Volte ao [portal de origem](https://dados.prefeitura.sp.gov.br/dataset/cadastro-de-escolas-municipais-conveniadas-e-privadas) e examine o dicionário de dados. Quais variáveis adicionais poderiam ser úteis para uma pesquisa sobre educação municipal?

Nos próximos tutoriais, aprenderemos a buscar informações em páginas HTML, extrair endereços de links, repetir coletas e consultar APIs. As operações que praticamos com *dplyr* continuarão aparecendo durante todo o curso.
