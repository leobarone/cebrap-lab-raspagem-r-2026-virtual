---
title: "Tutorial 3 — Dos links aos textos: raspagem de páginas com for loops"
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

No primeiro tutorial, capturamos uma tabela de parques nacionais da Wikipedia. No segundo, aprendemos como os documentos HTML são organizados, o que são elementos e atributos e como construir caminhos XPath e seletores CSS para localizar as informações que nos interessam.

Agora vamos juntar essas duas coisas.

Lembre-se de que os nomes dos parques, na tabela da Wikipedia, são **links**. Ao clicar no nome de um parque, chegamos a outra página, com um texto sobre ele. Nosso objetivo será aproveitar esses links para **visitar as páginas dos parques automaticamente e guardar seus textos em um data frame**.

Ao final da atividade, cada linha da nossa tabela corresponderá a uma página visitada, com o endereço utilizado na coleta e o texto dos parágrafos extraídos daquela página.

Vamos manter o código simples. Não precisamos começar tentando coletar dezenas de páginas. Primeiro vamos recuperar a tabela, encontrar os links e aprender a extrair o texto de **uma única página**. Depois aprenderemos a utilizar um **for loop** para repetir essa operação e guardar os resultados.

Essa é a ideia principal desta aula: aprender a fazer uma operação, entender por que ela funciona e só então pedir ao computador que a repita.

# Retomando nossa tabela de parques

Começaremos chamando os mesmos pacotes das atividades anteriores:

```{r carregar-pacotes}
library(rvest)
library(tidyverse)
```

Agora vamos guardar o endereço da lista de parques nacionais e capturar a página:

```{r capturar-lista-parques}
url_lista_parques <- "https://pt.wikipedia.org/wiki/Lista_de_parques_nacionais_do_Brasil"

pagina_lista_parques <- read_html(url_lista_parques)
```

Até aqui, nada de novo. `url_lista_parques` é um texto com o endereço; `pagina_lista_parques` é um documento HTML interpretado pelo R.

No primeiro tutorial utilizamos `html_table()` para transformar as tabelas do documento em data frames. Desta vez, porém, nosso interesse está também nos **endereços dos links**, guardados no atributo `href` dos elementos `a`.

Para não perder esses atributos, vamos selecionar primeiro a tabela **como um elemento HTML**, antes de transformá-la em data frame.

```{r selecionar-tabelas-como-elementos}
elementos_tabelas_pagina <- pagina_lista_parques %>%
  html_elements(css = "table")

length(elementos_tabelas_pagina)
```

A função `html_elements()` é a mesma que utilizamos no Tutorial 2. Ela seleciona os elementos indicados pelo caminho. No nosso caso, selecionamos os elementos `table` da página.

O resultado ainda não é uma lista de data frames. É um conjunto de **elementos HTML**, com o conteúdo e os atributos que aparecem dentro de cada tabela.

Vamos usar a posição que identificamos no primeiro tutorial:

```{r escolher-elemento-tabela}
posicao_tabela <- 1

elemento_tabela_parques <- elementos_tabelas_pagina[[posicao_tabela]]
```

Por que dois pares de colchetes? Porque queremos **extrair o elemento HTML** que ocupa essa posição, não uma lista que contém esse elemento. É a mesma diferença que estudamos ao trabalhar com listas.

Antes de continuar, vamos conferir nossa escolha. A função `html_table()` também pode receber diretamente um único elemento HTML que representa uma tabela:

```{r conferir-tabela-parques}
tabelas_parques <- html_table(elemento_tabela_parques)

names(tabelas_parques)
head(tabelas_parques)
```

Encontramos a tabela com os nomes dos parques? Se não, precisamos examinar os elementos da página e corrigir `posicao_tabela`. O número `1` indica apenas uma posição, não o significado da tabela.

Repare na diferença entre os objetos: `elemento_tabela_parques` ainda guarda a **estrutura HTML da tabela**; `tabelas_parques` é o **data frame** que resulta da extração. Vamos precisar do primeiro para encontrar os links.

# Selecionando os links dos parques

Volte à [lista de parques nacionais na Wikipedia](https://pt.wikipedia.org/wiki/Lista_de_parques_nacionais_do_Brasil) e use a opção **Inspecionar** sobre o nome de um parque.

No Tutorial 2 examinamos esta marcação para o Alto Cariri:

```html
<a rel="mw:WikiLink" href="https://pt.wikipedia.org/wiki/Parque_Nacional_do_Alto_Cariri" title="Parque Nacional do Alto Cariri" id="mw7Q">Alto Cariri</a>
```

Lembre-se da diferença: `Alto Cariri` é o **conteúdo** do elemento `a`; seu endereço está no atributo `href`.

Se observarmos os elementos ao redor, veremos que o link do nome do parque fica em uma célula de cabeçalho de linha (`th`) da tabela, dentro de uma linha (`tr`). Podemos utilizar essa estrutura para procurar os links.

## Construindo o caminho XPath

Vamos usar o seguinte caminho:

```text
.//tr/th[1]//a[@href]
```

Vamos traduzi-lo devagar:

- O ponto `.` indica que começamos **dentro do elemento já selecionado**, isto é, da tabela de parques.
- `//tr` procura as linhas da tabela, mesmo que existam elementos intermediários, como `tbody`.
- `/th[1]` escolhe a primeira célula `th` de cada linha, quando ela existe.
- `//a` procura os elementos `a` dentro dessas células.
- `[@href]` seleciona os elementos `a` que possuem o atributo `href`.

**Obs.:** `[1]`, aqui, faz parte da linguagem XPath. Estamos escolhendo a primeira célula `th` entre as células `th` de cada linha. Não são os colchetes que utilizamos para acessar posições de um vetor no R.

Agora podemos executar o caminho:

```{r selecionar-elementos-links}
elementos_links_tabela <- elemento_tabela_parques %>%
  html_elements(xpath = ".//tr/th[1]//a[@href]")

length(elementos_links_tabela)
head(elementos_links_tabela)
```

O resultado contém **elementos HTML**, e não uma lista de URLs. Observe que pode haver outros links nas células, como os que levam às notas de referência. Vamos identificar e separar aqueles que realmente apontam para páginas de parques.

Se preferíssemos CSS, poderíamos fazer uma busca semelhante com o seletor `tr > th a[href]`, usando `css` no lugar de `xpath`. Esse seletor não restringe a busca à primeira célula `th` de cada linha, mas ajuda a compreender como expressar o caminho em outra linguagem. Nesta atividade, utilizaremos XPath para recuperar os links da tabela e CSS mais adiante para selecionar os parágrafos.

## Extraindo o texto e o atributo `href`

Para obter os nomes escritos nos links, usamos `html_text()`:

```{r extrair-nomes-links}
nomes_links <- elementos_links_tabela %>%
  html_text(trim = TRUE)

head(nomes_links)
```

Já para obter os endereços, precisamos extrair o atributo `href`:

```{r extrair-enderecos-links}
enderecos_links <- elementos_links_tabela %>%
  html_attr("href")

head(enderecos_links)
```

Temos dois vetores: um com os textos clicáveis e outro com os endereços. Ambos foram extraídos **dos mesmos elementos, na mesma ordem**. Por isso podemos colocá-los lado a lado:

```{r criar-tabela-links}
tabela_links_parques <- tibble(
  nome_parque = nomes_links,
  endereco = enderecos_links
)

head(tabela_links_parques)
```

Reconhece a operação? No Tutorial 2 fizemos exatamente isso com nossa pequena página HTML de exemplo. Agora estamos aplicando a mesma lógica a uma página de verdade.

## Separando os endereços que nos interessam

Observe a tabela recém-criada. Podemos encontrar, junto aos links dos parques, outros endereços que aparecem nas células, como links para referências. Não queremos visitá-los.

Há um padrão útil nos endereços das páginas de parques desta lista: eles contêm o trecho `https://pt.wikipedia.org/wiki/`. Vamos utilizar esse trecho para filtrar as linhas, aproveitando o `filter()` que já conhecemos do *dplyr*:

```{r filtrar-links-dos-parques}
tabela_links_parques <- tabela_links_parques %>%
  filter(str_detect(endereco, "https://pt.wikipedia.org/wiki/"))

head(tabela_links_parques)
```

A novidade é `str_detect()`, função do pacote *stringr*, que faz parte do *tidyverse*. Ela verifica se um texto contém determinado padrão e devolve `TRUE` ou `FALSE`. Com `filter()`, mantemos apenas as linhas em que encontramos o trecho indicado.

Note uma vantagem de termos criado primeiro um data frame: **filtramos nomes e endereços ao mesmo tempo**. Assim, não corremos o risco de retirar um endereço de um vetor e deixar o nome correspondente no outro.

Este filtro foi escolhido para a estrutura que encontramos nesta página. Em outra pesquisa, os endereços poderão seguir padrões diferentes. Também não devemos supor que um artigo sempre terá o mesmo endereço ou que a Wikipedia nunca modificará sua estrutura.

Vamos conferir o resultado:

```{r conferir-tabela-de-links}
nrow(tabela_links_parques)
head(tabela_links_parques)
tail(tabela_links_parques)

nrow(tabelas_parques)
```

Compare o número de links com o número de linhas da tabela original. Os valores devem ser examinados, não simplesmente considerados corretos por serem parecidos. Se houver diferença, verifique se há linhas sem links, links repetidos ou algum parque excluído pelo nosso filtro.

Abra alguns dos endereços no navegador e confira se levam às páginas esperadas. **Na raspagem, examinar a coleta faz parte do trabalho**.

## Preparando nosso vetor de endereços

Nosso próximo desafio é visitar as páginas. Para isso, não precisamos carregar todas as colunas do data frame. Basta criar um vetor com os endereços:

```{r criar-vetor-urls}
url_parques <- tabela_links_parques %>%
  pull(endereco)

head(url_parques)
length(url_parques)
```

A função `pull()`, do pacote *dplyr*, extrai uma coluna de um data frame e devolve seus valores em um vetor. Aqui, `pull(endereco)` recupera os endereços da coluna `endereco`, na ordem em que aparecem na tabela. O resultado é um vetor de textos, no qual cada elemento é um endereço de página.

Observe a diferença em relação a muitos exemplos de raspagem: os `href` que encontramos **já são URLs absolutas**. Assim como aconteceu no exemplo do Alto Cariri, não precisamos juntar o domínio da Wikipedia a cada endereço.

**Obs.:** não vamos definir um número fixo de parques, como 74, 75 ou 76. O conteúdo da lista pode mudar. Nosso código utilizará os endereços efetivamente encontrados e conferidos.

## Conferindo se há endereços

Antes de visitar as páginas, vale fazer uma verificação simples:

```{r verificar-se-ha-enderecos}
stopifnot(length(url_parques) > 0)
```

A função `stopifnot()` interrompe o código quando a condição não é satisfeita. Aqui queremos evitar que o restante da atividade continue caso nenhum endereço tenha sido encontrado.

Se isso acontecer, volte aos elementos selecionados e ao filtro. Não adianta pedir ao R que repita uma coleta que ainda não funcionou.

## E se o endereço fosse relativo?

No Tutorial 2 também aprendemos que alguns sites utilizam URLs relativas. A Wikipedia, na página que examinamos, apresenta URLs absolutas, mas vale recuperar o caso de um endereço relativo para compreender a diferença.

Por exemplo, imagine que tivéssemos encontrado este valor de `href`:

```{r exemplo-endereco-relativo}
endereco_relativo <- "/wiki/Parque_Nacional_do_Itatiaia"

xml2::url_absolute(endereco_relativo, url_lista_parques)
```

A função `url_absolute()` recebe o endereço relativo e uma URL que serve de base para interpretá-lo. O resultado é o endereço completo. Usamos `xml2::` para chamar a função do pacote *xml2* sem carregar esse pacote com `library()`.

Se fornecermos um endereço que já é absoluto, a função não precisa acrescentar nada:

```{r exemplo-endereco-absoluto}
xml2::url_absolute(url_parques[1], url_lista_parques)
```

Esta é apenas uma demonstração para recuperar a explicação da aula anterior. **Não precisamos aplicar essa transformação ao vetor `url_parques`**, porque seus endereços já estão completos.

# Capturando o texto de uma única página

Excelente! Temos uma lista de endereços. Agora vamos resolver a captura de apenas uma página.

Vamos começar pelo segundo endereço do vetor (escolhemos o segundo como exemplo pois o primeiro parque não tem verbete na Wikipedia, apesar de haver link):

```{r escolher-primeiro-parque}
url_parque <- url_parques[2]
url_parque
```

Com `[2]`, selecionamos a segunda posição do vetor. Aqui não estamos extraindo um objeto de uma lista de tabelas, por isso basta um par de colchetes.

Vamos capturar a página:

```{r capturar-primeiro-parque}
pagina_parque <- read_html(url_parque)
```

A função continua fazendo a mesma coisa que no primeiro tutorial sobre este exemplo. Mudou apenas o endereço que usamos como argumento.

## Escolhendo os parágrafos

Abra o endereço no navegador e observe o texto. Como aprendemos, os parágrafos são identificados por elementos `p`.

Vamos selecionar os parágrafos da página utilizando diretamente o seletor CSS `p`:

```{r selecionar-paragrafos}
elementos_paragrafos <- pagina_parque %>%
  html_elements(css = "p")

length(elementos_paragrafos)
```

Leia o seletor: `p` indica que queremos encontrar os elementos de parágrafo da página. Não precisamos escrever um caminho mais longo para fazer essa seleção.

Agora extraímos o texto:

```{r extrair-texto-dos-paragrafos}
paragrafos <- elementos_paragrafos %>%
  html_text(trim = TRUE)

head(paragrafos)
```

O argumento `trim = TRUE` remove espaços nas extremidades do texto de cada elemento. Ele não faz uma limpeza completa do conteúdo.

Vamos conferir:

```{r examinar-paragrafos}
class(paragrafos)
length(paragrafos)
```

Temos um vetor. Cada elemento contém o texto de um parágrafo.

## Juntando os parágrafos em um texto

Queremos que cada linha do nosso data frame represente uma página. Seria conveniente, portanto, juntar os parágrafos em um único texto.

Vamos começar com um exemplo pequeno:

```{r exemplo-collapse}
exemplo_paragrafos <- c(
  "Este é o primeiro parágrafo.",
  "Este é o segundo parágrafo."
)

paste0(exemplo_paragrafos, collapse = " ")
```

O argumento `collapse = " "` informa que queremos reunir os elementos do vetor, colocando **um espaço entre eles**.

Atenção ao espaço entre as aspas. `collapse = ""` juntaria os elementos sem acrescentar separador, o que poderia colar a última palavra de um parágrafo à primeira do seguinte.

Agora fazemos isso com os parágrafos capturados:

```{r juntar-paragrafos}
texto <- paste0(paragrafos, collapse = " ")

length(texto)
nchar(texto)
```

`length(texto)` informa quantos elementos há no vetor: agora, um. `nchar(texto)` informa quantos caracteres há nesse texto.

Não confunda essas duas coisas. Podemos ter um vetor de comprimento um que contém um texto muito longo.

Pronto! Já sabemos capturar e reunir os parágrafos de uma página.

# Por que precisamos de um loop?

Imagine que queremos repetir a operação para cada endereço de `url_parques`.

Poderíamos trocar manualmente `[1]` por `[2]`, depois por `[3]`, e executar o código novamente. Mas isso seria trabalhoso e sujeito a erros.

Já sabemos o que precisa ser feito. Falta instruir o computador a fazer a mesma coisa para uma sequência de valores.

É para isso que usaremos um **for loop**.

*Loop* é uma repetição de instruções. Cada passagem por essas instruções é uma **iteração**. No nosso exemplo, cada iteração corresponderá à visita a uma página.

Vamos deixar a internet de lado por um momento e entender a estrutura com números.

# Entendendo um `for` com um exemplo pequeno

Comece por uma sequência:

```{r sequencia-de-numeros}
1:5
```

O operador `:` produz, neste caso, os números inteiros de 1 a 5.

Agora observe:

```{r primeiro-for}
for (i in 1:5) {
  print(i)
}
```

Podemos ler a instrução assim: **para cada número `i` no conjunto que vai de 1 a 5, imprima o número `i`**.

O nome `i` não tem nenhum poder especial. É apenas o nome do objeto que receberá um valor de cada vez.

Na primeira passagem, `i` vale 1. Na segunda, vale 2. Na terceira, vale 3. O R continua até percorrer a sequência inteira.

O que está entre as chaves `{` e `}` é o conjunto de instruções que será repetido.

## O que acontece em cada iteração?

Podemos pensar no exemplo como esta sequência de operações:

| Iteração | Valor de `i` | Instrução executada |
|:---|:---|:---|
| Primeira | `1` | `print(1)` |
| Segunda | `2` | `print(2)` |
| Terceira | `3` | `print(3)` |
| Quarta | `4` | `print(4)` |
| Quinta | `5` | `print(5)` |

Não precisamos escrever cada uma dessas instruções. O loop faz a repetição por nós.

Também não precisamos criar `i` antes do loop nem escrever uma instrução para somar 1 a cada passagem. O `for` recebe os valores da sequência.

Vamos modificar o que acontece dentro das chaves:

```{r tabuada-do-sete}
for (i in 1:5) {
  print(i * 7)
}
```

Agora imprimimos cada número multiplicado por 7.

Simples, não? Mudamos a tarefa, mas mantivemos a estrutura da repetição.

**Exercício:** faça um loop que imprima os números de 3 a 8 multiplicados por 10. O que precisa mudar dentro dos parênteses? E dentro das chaves?

## Mais de uma instrução dentro do loop

Podemos colocar várias instruções no mesmo bloco:

```{r for-com-duas-instrucoes}
for (i in 1:3) {
  resultado <- i * 7
  print(resultado)
}
```

Em cada passagem, o R calcula o resultado e depois o imprime.

Uma instrução escrita **depois da chave de fechamento** só será executada quando todas as iterações terminarem.

A indentação ajuda a enxergar o bloco. Mas são as chaves que delimitam quais instruções estão dentro dele.

# Loops também percorrem textos

Não precisamos trabalhar apenas com números. Um `for` pode percorrer um vetor de textos:

```{r for-com-nomes}
nomes_exemplo <- c("Alto Cariri", "Caparaó", "Itatiaia", "Tijuca")

for (nome in nomes_exemplo) {
  print(nome)
}
```

Na primeira passagem, `nome` recebe `"Itatiaia"`. Na segunda, recebe `"Tijuca"`.

Observe a diferença entre o nome do objeto e seu conteúdo. `print(nome)` imprime o valor que está no objeto. `print("nome")` imprimiria sempre a palavra “nome”.

Podemos fazer exatamente isso com os endereços dos parques.

## Percorrendo nosso vetor de URLs

Vamos criar um vetor pequeno para testar:

```{r escolher-urls-de-teste}
urls_teste <- head(url_parques, 3)

urls_teste
```

Até agora usamos `head()` para observar objetos. Mas a função também **devolve** os primeiros elementos. Aqui guardamos até três endereços em um novo vetor.

O vetor completo, `url_parques`, continua intacto.

Agora percorremos os endereços:

```{r for-com-urls}
for (url_parque in urls_teste) {
  print(url_parque)
}
```

O que aconteceu?

R pegou o primeiro endereço de `urls_teste`, colocou esse valor em `url_parque` e executou `print(url_parque)`. Depois fez a mesma coisa com o endereço seguinte.

`url_parque` contém o **endereço**, não o número de sua posição. Não precisamos escrever `urls_teste[url_parque]`.

Compare com o código de captura de uma página. Lá já usamos um objeto chamado `url_parque` como argumento de `read_html()`. Dentro do loop, faremos a mesma coisa. A diferença é que o valor de `url_parque` será atualizado a cada passagem.

# Repetir não é o mesmo que guardar os resultados

Antes de montar a coleta, precisamos resolver um problema.

Veja este exemplo:

```{r sobrescrevendo-um-objeto}
for (i in 1:3) {
  resultado <- i * 7
}

resultado
```

Ao final, `resultado` contém apenas 21.

Onde foram parar 7 e 14? Foram substituídos pelos valores das iterações seguintes.

Se colocarmos no loop apenas as instruções que criam `pagina_parque`, `paragrafos` e `texto`, acontecerá a mesma coisa: ao final teremos nesses objetos apenas o resultado da última página.

Também não basta imprimir os textos. `print()` ajuda a observar, mas não organiza as diferentes páginas em um data frame.

Precisamos de um objeto que **acumule** os resultados.

# Guardando cada página em um data frame

Nosso resultado terá duas colunas:

| Coluna | Conteúdo |
|:---|:---|
| `url_pagina_parque` | Endereço utilizado para capturar a página. |
| `texto_parque` | Texto dos parágrafos selecionados, reunidos em um único elemento. |

Cada linha corresponderá a uma página.

Vamos começar com dois resultados fictícios, sem fazer novas solicitações à internet:

```{r criar-linhas-de-exemplo}
linha_exemplo1 <- tibble(
  url_pagina_parque = "https://exemplo.org/parque1",
  texto_parque = "Texto do primeiro parque."
)

linha_exemplo2 <- tibble(
  url_pagina_parque = "https://exemplo.org/parque2",
  texto_parque = "Texto do segundo parque."
)
```

A função `tibble()` constrói uma tabela. Como cada coluna recebeu um único valor, cada objeto tem uma linha.

Para colocar uma linha embaixo da outra, usamos `bind_rows()`:

```{r unir-linhas-de-exemplo}
bind_rows(linha_exemplo1, linha_exemplo2)
```

Reconhece essa função? Ela faz parte do *dplyr*. O que vamos construir no loop é exatamente esse processo, repetido a cada página.

## Criando um lugar para acumular a coleta

Antes do loop, vamos escrever:

```{r iniciar-tabela-de-resultados}
tabela_textos_parques <- NULL
```

`NULL` indica a ausência de um resultado. Por enquanto, `tabela_textos_parques` **ainda não é um data frame**.

A função `bind_rows()` aceita esse ponto de partida. Na primeira iteração, receberá `NULL` e a primeira linha capturada. O resultado será uma tabela com uma linha.

Na segunda, receberá a tabela já existente e uma nova linha. O resultado terá duas linhas. E assim por diante.

**Atenção:** a inicialização precisa ficar fora do loop. Se escrevermos `tabela_textos_parques <- NULL` dentro das chaves, apagaremos os resultados acumulados a cada passagem.

# Um cuidado antes de repetir solicitações

Vamos incluir uma pausa entre as capturas:

```{r exemplo-de-pausa, eval=FALSE}
Sys.sleep(2)
```

A função suspende a execução por 2 segundos.

No loop, a pausa ficará antes de cada solicitação. Isso ajuda a evitar acessos em sequência muito rápida. Não significa, porém, que qualquer quantidade de solicitações esteja autorizada.

A Wikimedia possui orientações para acesso automatizado, inclusive identificação do programa e respeito a limites. A pausa não substitui essas orientações. Para uma coleta de pesquisa, consulte-as antes de ampliar a atividade: [Robot policy](https://wikitech.wikimedia.org/wiki/Robot_policy). Se o servidor devolver um erro de acesso ou de limite, pare e verifique a situação. Não vamos insistir repetidamente nem tentar contornar bloqueios.

# Juntando tudo: a coleta de teste

Agora leia o código com calma. Quase todas as partes já apareceram separadamente.

O único trabalho novo é colocá-las na ordem certa dentro da repetição:

```{r coletar-paginas-de-teste}
tabela_textos_parques <- NULL

for (url_parque in urls_teste) {

  print(url_parque)
  Sys.sleep(2)

  pagina_parque <- read_html(url_parque)

  paragrafos <- pagina_parque %>%
    html_elements(css = "p") %>%
    html_text(trim = TRUE)


  texto <- paste0(paragrafos, collapse = " ")

  linha_parque <- tibble(
    url_pagina_parque = url_parque,
    texto_parque = texto
  )

  tabela_textos_parques <- bind_rows(tabela_textos_parques, linha_parque)

}
```

Vamos traduzir o que fizemos.

`for (url_parque in urls_teste)` informa quais valores serão percorridos. Em cada passagem, `url_parque` recebe um dos endereços do vetor.

`print(url_parque)` mostra a página que será capturada. É uma forma simples de acompanhar o processo. `Sys.sleep(2)` faz a pausa.

`read_html(url_parque)` captura a página daquele endereço.

As três linhas seguintes selecionam os elementos `p` da página e extraem seus textos.

`paste0()` reúne os parágrafos em um único texto.

`tibble()` cria uma linha com o endereço e o texto da página.

Por fim, `bind_rows()` junta a tabela que já existia à nova linha e guarda o resultado novamente em `tabela_textos_parques`.

Ufa! Leia de novo. O código ficou maior porque agora estamos fazendo todas as etapas juntas. Mas não há uma nova função escondida no meio da solução.

## A linha mais importante para o armazenamento

Observe especialmente:

```{r explicar-acumulacao, eval=FALSE}
tabela_textos_parques <- bind_rows(tabela_textos_parques, linha_parque)
```

À direita de `<-`, usamos o conteúdo que `tabela_textos_parques` já tinha e acrescentamos `linha_parque`.

À esquerda, substituímos o objeto pelo resultado dessa união.

Não estamos perdendo as linhas anteriores, porque elas participam da construção do novo resultado.

É diferente de escrever apenas:

```{r exemplo-que-nao-acumula, eval=FALSE}
tabela_textos_parques <- linha_parque
```

Essa segunda versão manteria somente a última linha.

# Examinando o que foi coletado

Se todas as iterações terminaram, vamos conferir:

```{r conferir-quantidades}
nrow(tabela_textos_parques)
length(urls_teste)

nrow(tabela_textos_parques) == length(urls_teste)
```

A comparação deve retornar `TRUE`.

Isso informa que guardamos uma linha por endereço de teste. Ainda precisamos olhar o conteúdo:

```{r examinar-resultado}
glimpse(tabela_textos_parques)
```


```{r visualizar-resultado, eval=FALSE}
View(tabela_textos_parques)
```

## Uma conferência simples do tamanho dos textos

Vamos recuperar o que já sabemos de *dplyr*:

```{r conferir-tamanho-dos-textos}
conferencia <- tabela_textos_parques %>%
  mutate(n_caracteres = nchar(texto_parque)) %>%
  select(url_pagina_parque, n_caracteres)

conferencia
```

Um texto vazio ou muito curto pode indicar um problema de seleção ou de acesso. Também pode ser uma característica da página. Precisamos investigar, não presumir que todas as diferenças sejam erros. Por exemplo, no momento em que este tutorial foi elaborado, o Parque Nacional do Acari não tinha verberte e o resultado foi uma mensagem padrão de verbete vazio da Wikipedia.

A função `nchar()` não mede qualidade da coleta. Ela nos dá apenas uma informação útil para decidir o que examinar.

# Coletando todos os parques nacionais

O que precisamos alterar para visitar todos os endereços?

A lógica do loop não muda. Em vez de percorrer `urls_teste`, precisamos percorrer `url_parques`.

Essa é a vantagem de ter separado o que varia — o endereço — das instruções que se repetem.

No código completo abaixo, a única diferença no conjunto de páginas percorrido é:

```{r cabecalho-loop-completo, eval=FALSE}
for (url_parque in url_parques) {
  # Aqui entram as mesmas instruções de captura e armazenamento.
}
```

Não precisamos escrever uma instrução para cada parque nem fixar previamente a quantidade de parques.

A coleta completa deve começar com uma nova inicialização de `tabela_textos_parques`, **fora do loop**. Caso contrário, poderíamos acrescentar as páginas completas às páginas de teste e criar repetições.

# Código completo da coleta

Vamos juntar agora os comandos principais, sem todas as explicações. Observe como o programa não ficou muito diferente do que construímos passo a passo.

```{r codigo-completo, eval=FALSE}
library(rvest)
library(tidyverse)

# Capturar a página com a lista dos parques.
url_lista_parques <- "https://pt.wikipedia.org/wiki/Lista_de_parques_nacionais_do_Brasil"
pagina_lista_parques <- read_html(url_lista_parques)

# Selecionar a tabela como elemento HTML.
elementos_tabelas_pagina <- pagina_lista_parques %>%
  html_elements(css = "table")

posicao_tabela <- 1
elemento_tabela_parques <- elementos_tabelas_pagina[[posicao_tabela]]

# Conferir a tabela selecionada.
tabelas_parques <- html_table(elemento_tabela_parques)
head(tabelas_parques)

# Selecionar os links e extrair texto e href.
elementos_links_tabela <- elemento_tabela_parques %>%
  html_elements(xpath = ".//tr/th[1]//a[@href]")

nomes_links <- elementos_links_tabela %>%
  html_text(trim = TRUE)

enderecos_links <- elementos_links_tabela %>%
  html_attr("href")

# Organizar os pares nome-endereco e manter links de parques.
tabela_links_parques <- tibble(
  nome_parque = nomes_links,
  endereco = enderecos_links
) %>%
  filter(str_detect(endereco, "/wiki/Parque_Nacional"))

url_parques <- tabela_links_parques %>%
  pull(endereco)

head(tabela_links_parques)
length(url_parques)
stopifnot(length(url_parques) > 0)

# Iniciar a tabela que guardará os textos.
tabela_textos_parques <- NULL

# Visitar cada página e guardar seu texto.
for (url_parque in url_parques) {

  print(url_parque)
  Sys.sleep(2)

  pagina_parque <- read_html(url_parque)

  paragrafos <- pagina_parque %>%
    html_elements(css = "p") %>%
    html_text(trim = TRUE)

  stopifnot(length(paragrafos) > 0)

  texto <- paste0(paragrafos, collapse = " ")

  linha_parque <- tibble(
    url_pagina_parque = url_parque,
    texto_parque = texto
  )

  tabela_textos_parques <- bind_rows(tabela_textos_parques, linha_parque)

}

# Conferir e salvar.
nrow(tabela_textos_parques)
length(url_parques)

write_csv(tabela_textos_parques, "textos-parques.csv")
```

Pronto! Começamos por uma tabela da Wikipedia, selecionamos links dentro de seus elementos HTML e chegamos a uma coleção de textos organizada em um data frame.

Agora observe as etapas: primeiro **localizamos** os elementos; depois **extraímos** os endereços; aprendemos a **repetir** a leitura de uma página; e, por fim, **armazenamos** os resultados. É essa sequência de operações que poderemos aproveitar em outras pesquisas.

# Levando a lógica para uma pesquisa

O código não escolhe uma pergunta de pesquisa por nós. Neste exercício, reunimos os parágrafos de artigos sobre parques nacionais. Isso não transforma os textos em um inventário oficial nem garante que todos os artigos tenham a mesma quantidade de informação.

Antes de analisar, precisamos definir o que essas páginas representam, por que foram selecionadas e quais partes de seu conteúdo entraram na coleta. Observe também que não capturamos tudo: selecionamos elementos `p` da página. Títulos, listas, tabelas e imagens não necessariamente entraram nos nossos textos.

Registre a fonte, a data da coleta e os critérios de seleção. A URL guardada em cada linha ajuda a voltar à origem de um texto. Uma página pode mudar depois da coleta, portanto vale preservar o arquivo gerado.

**Exercício final:** o que precisaríamos alterar para aplicar o mesmo procedimento a uma lista de notícias, decisões judiciais ou outras páginas de interesse de uma pesquisa? Qual parte do código depende da estrutura HTML do site? Qual parte é basicamente a mesma?

Se você conseguir responder a essas perguntas, compreendeu o mais importante: a raspagem exige conhecer a página, mas a lógica de **selecionar, extrair, repetir e guardar** pode ser reaproveitada.

# [Extra] Identificação da coleta na Wikipedia

A Wikimedia, responsável pela Wikipedia, tem regras para solicitações automatizadas. Programas que acessam o site devem usar um *User-Agent* informativo, que permita identificar o responsável pelo acesso. Além disso, devemos evitar um volume de solicitações que sobrecarregue o serviço.

Para manter o aprendizado centrado na raspagem, utilizamos nos exemplos a forma curta de `read_html()`. Mas, para uma coleta automatizada real, o responsável pela atividade deve configurar a identificação apropriada. Uma maneira é usar o pacote *curl*:

```{r configurar-identificacao, eval=FALSE}
identificacao <- curl::new_handle(
  useragent = "CursoRaspagemR/1.0 (mailto:SEU_EMAIL_INSTITUCIONAL)"
)
```

**Não use esse endereço de exemplo literalmente.** Substitua-o por um contato válido do responsável. Com essa identificação, a leitura pode ser feita assim:

```{r ler-com-identificacao, eval=FALSE}
pagina_lista_parques <- read_html(
  curl::curl(url_lista_parques, handle = identificacao)
)

pagina_parque <- read_html(
  curl::curl(url_parque, handle = identificacao)
)
```

Na coleta completa, a segunda instrução deve substituir a chamada de `read_html(url_parque)` que está dentro do loop. Os comandos de seleção com `html_elements()` e de extração com `html_text()` ou `html_attr()` continuam iguais. A identificação não é uma maneira de contornar restrições: precisamos também respeitar as condições de acesso ao site.
