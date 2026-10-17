---
title: "Tutorial 2 — HTML, XML e caminhos para encontrar informações"
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

Na primeira atividade, capturamos uma tabela de parques nacionais da Wikipedia. Como as informações já estavam organizadas em uma tabela HTML, a função `html_table()` fez boa parte do trabalho por nós.

O que fazer, entretanto, quando a informação que queremos não está em uma tabela? Como obter os endereços dos links? E como escolher apenas os parágrafos de uma página, sem trazer também seus menus e outros elementos?

Precisamos conhecer um pouco melhor a estrutura do documento que capturamos.

Vamos fazer uma pausa na coleta e trabalhar com exemplos pequenos, todos relacionados a parques nacionais. Primeiro veremos como organizar informações em XML. Depois construiremos uma página HTML bastante simples e aprenderemos a indicar onde estão as informações que queremos extrair.

Não precisamos aprender a desenvolver sites. Precisamos, sobretudo, compreender como um documento está organizado e como localizar partes dele.

**Obs.:** os blocos identificados como HTML, XML, CSS ou texto servem para leitura. Eles não são comandos de R. Os blocos de R aparecem mais adiante, quando usaremos o que aprendemos para fazer pequenas extrações.

# XML: organizando informações com marcações

XML significa *Extensible Markup Language*, ou linguagem de marcação extensível. O nome parece complicado, mas vamos separar suas partes.

É uma linguagem de **marcação** porque usamos marcas, chamadas *tags*, para identificar e organizar os conteúdos. É **extensível** porque podemos definir nomes de elementos adequados às informações que queremos representar.

Por exemplo, imagine que queremos guardar nomes de parques e os estados em que eles estão localizados:

```xml
<parques>
  <parque>
    <nome>Itatiaia</nome>
    <estados>
      <estado>Minas Gerais</estado>
      <estado>Rio de Janeiro</estado>
    </estados>
  </parque>
  <parque>
    <nome>Tijuca</nome>
    <estados>
      <estado>Rio de Janeiro</estado>
    </estados>
  </parque>
</parques>
```

Avance devagar. O documento inteiro está dentro de `parques`. Dentro dele temos dois elementos chamados `parque`. Cada parque tem um `nome` e um conjunto de `estados`, no plural mesmo, pois um parque nacional pode ocupar áreas em duas unidades da federação diferentes, como no exemplo do Parque Nacional de Itatiaia.

Os nomes `parques`, `parque`, `nome` e `estado` foram escolhidos para este exemplo. O XML não traz uma lista obrigatória de tags para representar parques nacionais.

É essa possibilidade de definir uma estrutura que torna o formato útil para organizar e trocar dados.

## Tags de abertura, tags de fechamento e conteúdo

Observe apenas esta linha:

```xml
<nome>Itatiaia</nome>
```

`<nome>` é a tag de abertura. `</nome>` é a tag de fechamento. `Itatiaia` é o conteúdo textual que colocamos entre elas.

A barra `/` identifica o fechamento. Não é a mesma coisa que a barra invertida `\`.

O conjunto formado pelas marcações e pelo conteúdo constitui um **elemento**. No uso cotidiano, às vezes dizemos “a tag nome” para nos referirmos a esse conjunto. Vale, porém, saber a diferença: a tag é a marcação; o elemento inclui também seu conteúdo.

O conteúdo de um elemento não precisa ser apenas texto. Veja:

```xml
<estados>
  <estado>Minas Gerais</estado>
  <estado>Rio de Janeiro</estado>
</estados>
```

O elemento `estados` contém outros elementos.

Não são linhas independentes colocadas uma depois da outra. Há uma organização: os dois estados estão dentro do mesmo conjunto.

## Hierarquia: pais, filhos e descendentes

Essa organização forma uma hierarquia.

No nosso documento, `parques` contém os elementos `parque`. Dizemos que `parques` é o **pai** desses elementos, e que cada `parque` é um **filho** de `parques`.

Dentro de cada `parque`, os elementos `nome` e `estados` são filhos diretos. Já `estado` é filho de `estados`, não de `parque`.

Podemos representar um pedaço dessa estrutura assim:

```text
parques
  parque
    nome
    estados
      estado
      estado
```

`estado` é, portanto, um **descendente** de `parque`, mas não um filho direto.

Guarde bem essa diferença. Daqui a pouco usaremos caminhos diferentes para procurar filhos diretos e descendentes em qualquer nível.

**Obs.:** os espaços no começo das linhas ajudam a enxergar a hierarquia. Quem estabelece a relação entre os elementos, porém, são as marcações de abertura e fechamento. Só indentar uma linha não coloca um elemento dentro de outro.

## Algumas regras básicas

Em um XML bem formado, os elementos precisam se encaixar corretamente. Se abrimos `parque` e depois `nome`, precisamos fechar `nome` antes de fechar `parque`.

Também precisamos de um único elemento principal, chamado **raiz**, que envolva os demais. No exemplo, a raiz é `parques`.

Os nomes diferenciam letras maiúsculas de minúsculas. Abrir `<nome>` e fechar `</Nome>` não é a mesma coisa.

Há ainda elementos vazios, sem conteúdo. Eles podem ser escritos, por exemplo, como `<observacao/>`. Não precisamos deles nesta atividade, mas isso explica por que nem toda marcação que encontramos vem acompanhada de uma tag de fechamento separada.

Não é necessário decorar todas as regras do XML. Nosso primeiro objetivo é reconhecer que as informações têm uma estrutura.

## XML e data frames

Agora pense no exemplo como alguém que vai analisar dados.

Quantas linhas teria um data frame construído a partir dele?

A resposta depende de **o que cada linha representa**.

Se cada linha representar um parque, teremos duas linhas. Mas precisaremos decidir o que fazer com os dois estados de Itatiaia: colocá-los na mesma célula? Criar outra tabela?

Se cada linha representar a relação entre um parque e um estado, teremos:

| Parque | Estado |
|:---|:---|
| Itatiaia | Minas Gerais |
| Itatiaia | Rio de Janeiro |
| Tijuca | Rio de Janeiro |

São três linhas, não duas.

Excelente! O XML não é uma planilha disfarçada. Ele permite representar elementos dentro de outros elementos, inclusive situações em que uma observação tem várias informações associadas.

Na pesquisa, transformar essa estrutura em uma tabela exige definir a unidade de observação.

Vamos agora acrescentar mais uma informação ao nosso exemplo. Imagine que, além dos estados, queremos registrar algumas **trilhas de cada parque**. Uma possibilidade seria organizar o XML da seguinte maneira:

```xml
<parques>
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
  <parque>
    <nome>Tijuca</nome>
    <estados>
      <estado>Rio de Janeiro</estado>
    </estados>
    <trilhas>
      <trilha>
        <nome>Trilha da Floresta</nome>
        <extensao_km>2.5</extensao_km>
        <dificuldade>Fácil</dificuldade>
      </trilha>
      <trilha>
        <nome>Trilha do Vale</nome>
        <extensao_km>4.0</extensao_km>
        <dificuldade>Moderada</dificuldade>
      </trilha>
      <trilha>
        <nome>Trilha do Pico</nome>
        <extensao_km>7.1</extensao_km>
        <dificuldade>Difícil</dificuldade>
      </trilha>
    </trilhas>
  </parque>
</parques>
```

**Obs.:** os nomes e as características das trilhas são fictícios. Estamos apenas criando um exemplo para compreender como as informações podem ser organizadas.

Observe o que mudou. Cada `parque` agora contém um elemento `trilhas`, dentro do qual podemos encontrar vários elementos `trilha`. E cada trilha tem suas próprias informações: `nome`, `extensao_km` e `dificuldade`.

Como transformar esse XML em um data frame? Novamente, precisamos decidir o que cada linha representa. Se nosso interesse é analisar **as trilhas**, podemos criar uma linha para cada uma delas:

| Parque | Trilha | Extensão (km) | Dificuldade |
|:---|:---|---:|:---|
| Itatiaia | Trilha do Mirante | 3,2 | Fácil |
| Itatiaia | Trilha da Cachoeira | 5,0 | Moderada |
| Tijuca | Trilha da Floresta | 2,5 | Fácil |
| Tijuca | Trilha do Vale | 4,0 | Moderada |
| Tijuca | Trilha do Pico | 7,1 | Difícil |

Temos agora **cinco linhas**, embora continuemos trabalhando com apenas dois parques. O nome de Itatiaia aparece duas vezes e o da Tijuca aparece três. Isso não é um erro: cada linha representa uma trilha, e não um parque.

Note também que `extensao_km` e `dificuldade`, que apareciam como elementos dentro de cada `trilha` no XML, viraram **colunas** no data frame. Já as diferentes trilhas, que eram elementos repetidos no XML, viraram **linhas**.

Simples, não? É a mesma lógica que utilizamos para os estados, mas agora cada parque possui também um conjunto de trilhas, cada uma com suas próprias características. Um XML pode guardar todos esses níveis juntos. Para analisar os dados em tabelas, precisamos pensar com cuidado em qual é a nossa **unidade de observação**. Neste caso, escolhemos a trilha.

# HTML: organizando uma página de internet

Vamos agora a outro tipo de documento.

HTML significa *HyperText Markup Language*, ou linguagem de marcação de hipertexto. Também utiliza marcações, mas seu vocabulário identifica elementos de uma página: títulos, parágrafos, listas, links, tabelas e assim por diante.

Diferentemente do nosso exemplo XML, não vamos inventar uma tag para cada variável da pesquisa. Utilizaremos elementos com funções já definidas, como `p` para parágrafos e `a` para links.

O navegador interpreta esse documento e apresenta a página para quem está lendo.

## Nossa primeira página HTML

Vamos começar com um exemplo pequeno:

```html
<!DOCTYPE html>
<html lang="pt-BR">
  <head>
    <meta charset="UTF-8">
    <title>Parques nacionais</title>
  </head>
  <body>
    <h1>Conhecendo os parques nacionais</h1>
    <p>Esta é nossa primeira página sobre parques.</p>
    <p>Vamos usá-la para aprender a capturar informações.</p>
  </body>
</html>
```

Parece com XML, não? Temos elementos dentro de outros elementos.

Vamos ler por partes. `<!DOCTYPE html>` é uma declaração do tipo de documento; não é um elemento de conteúdo como `p`. O elemento `html` envolve a página. Dentro dele encontramos duas partes principais: `head` e `body`.

`head` contém informações sobre o documento. No exemplo, `title` define o título que aparece na aba do navegador, e `meta charset="UTF-8"` informa a codificação utilizada.

`body` contém o conteúdo da página. Ali estão nosso título visível, marcado com `h1`, e dois parágrafos, marcados com `p`.

**Atenção:** `title` e `h1` não são a mesma coisa. Trocar o texto de `title` muda o título do documento na aba; trocar o texto de `h1` muda o título dentro do corpo da página.

## Experimentando no navegador

Copie o exemplo para um editor de texto simples (como notepad) e salve como `parques.html`, em UTF-8. Não use um documento do Word: precisamos de texto simples.

Abra o arquivo no navegador.

Você não verá as tags escritas na página. Verá o resultado da interpretação delas: um título e dois parágrafos.

Agora altere o texto de um parágrafo, salve o arquivo e atualize a página no navegador.

Pronto! Acabamos de construir e modificar uma página HTML. Não foi necessário colocá-la em um servidor. Por enquanto, estamos apenas abrindo um arquivo do nosso computador.

**Exercício:** acrescente um terceiro parágrafo. Depois coloque um subtítulo com `h2` entre o primeiro e o segundo parágrafos. O que muda?

## Títulos, parágrafos e ênfase

Os títulos e subtítulos podem ser representados por `h1`, `h2`, até `h6`. Os números indicam níveis na organização do conteúdo, não uma sequência de parágrafos.

Observe:

```html
<h1>Parques nacionais</h1>
<h2>Parque Nacional do Itatiaia</h2>
<p>Este parágrafo apresenta o parque.</p>
<h2>Parque Nacional da Tijuca</h2>
<p>Este parágrafo apresenta outro parque.</p>
```

Também podemos marcar uma parte do texto dentro de um parágrafo:

```html
<p>Vamos estudar <strong>dois parques</strong> nesta atividade.</p>
<p>A informação mais importante é <em>onde cada elemento está</em>.</p>
```

`strong` marca importância; `em` marca ênfase. A aparência costuma ser negrito e itálico, respectivamente, mas não devemos confundir a função do elemento com uma aparência obrigatória.

Observe também a hierarquia: `strong` e `em` estão dentro de elementos `p`.

## Listas e seus itens

Para organizar uma lista sem numeração, usamos `ul`. Cada item é marcado com `li`:

```html
<ul>
  <li>Itatiaia</li>
  <li>Tijuca</li>
</ul>
```

Uma lista ordenada utiliza `ol`:

```html
<ol>
  <li>Abrir a página.</li>
  <li>Identificar a informação.</li>
  <li>Extrair os dados.</li>
</ol>
```

`ul` e `ol` identificam a lista; `li` identifica cada item. Essa distinção será útil quando encontrarmos páginas com listas de notícias, publicações ou resultados de pesquisa.

## Tabelas: voltando ao primeiro tutorial

Uma tabela HTML pode ser escrita assim:

```html
<table>
  <tr>
    <th>Parque</th>
    <th>Estados</th>
  </tr>
  <tr>
    <td>Itatiaia</td>
    <td>Minas Gerais e Rio de Janeiro</td>
  </tr>
  <tr>
    <td>Tijuca</td>
    <td>Rio de Janeiro</td>
  </tr>
</table>
```

`table` envolve a tabela. Cada `tr` representa uma linha. `th` identifica uma célula de cabeçalho, enquanto `td` identifica uma célula de dados.

Note que uma linha não é uma única célula. No exemplo, cada `tr` contém duas células.

Também podemos encontrar `thead` e `tbody`, que agrupam linhas do cabeçalho e do corpo da tabela. Além disso, uma célula `th` pode servir de cabeçalho de uma **linha**, e não apenas de uma coluna.

Agora fica mais fácil compreender o trabalho de `html_table()`: a função reconhece essa organização e a transforma em uma tabela no R.

## Outros elementos que encontraremos

Não precisamos memorizar um catálogo. Basta reconhecer os mais frequentes:

| Elemento | O que identifica |
|:---|:---|
| `html`, `head`, `body` | A página, suas informações gerais e seu corpo. |
| `h1` a `h6`, `p` | Títulos de diferentes níveis e parágrafos. |
| `a` | Um link, quando acompanhado de `href`. |
| `ul`, `ol`, `li` | Listas e seus itens. |
| `table`, `tr`, `th`, `td` | Tabela, linha, célula de cabeçalho e célula de dados. |
| `div`, `span` | Contêineres genéricos para agrupar conteúdo. |
| `strong`, `em` | Importância e ênfase em partes do texto. |
| `img`, `br` | Uma imagem e uma quebra de linha. |

`div` aparece muito em páginas reais. Podemos usá-lo para reunir o título, o texto e o link de um parque em um mesmo bloco. `span` também agrupa conteúdo, frequentemente um pequeno trecho dentro de uma linha de texto.

Alguns poucos elementos HTML, como `img`, `br` e `meta`, **não têm tag de fechamento**.

## HTML é um tipo de XML?

A semelhança é útil para nosso aprendizado, mas precisamos fazer uma distinção: **um documento HTML não é necessariamente um documento XML**. HTML possui regras próprias de interpretação.

O importante para a raspagem é que as ferramentas de R conseguem representar tanto HTML quanto XML da mesma maneira, como estruturas de elementos organizados hierarquicamente. Por isso que, no exercício de raspagem da tabela de parques nacionais, quando inspecionamos a classe da página capturada com `read_html()` obtivemos como resultado `xml_document`.

# Atributos: informações sobre os elementos

Até agora olhamos principalmente para o que está entre as tags. Mas também podemos colocar informações **dentro da tag de abertura**.

Veja este exemplo XML:

```xml
<estado sigla="MG">Minas Gerais</estado>
```

`estado` é o nome do elemento. `Minas Gerais` é seu conteúdo. `sigla` é o nome de um **atributo**, e `MG` é o valor desse atributo.

A informação não desapareceu. Ela apenas foi organizada de outra maneira: parte está no conteúdo e parte está em um atributo.

No nosso exemplo, podemos escrever:

```xml
<estados>
  <estado sigla="MG">Minas Gerais</estado>
  <estado sigla="RJ">Rio de Janeiro</estado>
</estados>
```

É uma escolha de representação. Atributos não são exclusivos do HTML nem servem apenas para a aparência de uma página.

## `id` e `class` no HTML

No HTML, dois atributos bastante úteis para localizar informações são `id` e `class`.

```html
<div id="itatiaia" class="parque">
  <h2>Itatiaia</h2>
  <p>Texto de apresentação do parque.</p>
</div>
```

O `id` identifica um elemento específico. Em um documento corretamente organizado, seu valor deve ser único na página.

A `class` permite identificar um grupo de elementos. Podemos ter vários blocos com `class="parque"`, um para cada parque.

Um elemento também pode pertencer a mais de uma classe:

```html
<div id="tijuca" class="parque destaque">
  <h2>Tijuca</h2>
</div>
```

Aqui temos duas classes: `parque` e `destaque`. Não é uma única classe com um nome que contém um espaço.

Os nomes dessas classes foram escolhidos por quem escreveu a página. Em outro site, os mesmos tipos de conteúdo podem aparecer com nomes completamente diferentes.

## `href`: onde está o endereço de um link?

Este é um ponto fundamental para a próxima atividade.

Observe este trecho do HTML da lista de parques nacionais da Wikipedia:

```html
<a rel="mw:WikiLink" href="https://pt.wikipedia.org/wiki/Parque_Nacional_do_Alto_Cariri" title="Parque Nacional do Alto Cariri" id="mw7Q">Alto Cariri</a>
```

O navegador mostra a expressão **Alto Cariri** como texto clicável. O endereço para o qual o link aponta está no atributo **`href`**.

O elemento tem também outros atributos, como `rel`, `title` e `id`. Não precisamos utilizá-los agora. Observe principalmente que o `href` contém um **endereço completo**, começando com `https://` e incluindo o domínio `pt.wikipedia.org`.

São duas informações diferentes:

| Informação | Onde está |
|:---|:---|
| `Alto Cariri` | No conteúdo do elemento `a`. |
| `https://pt.wikipedia.org/wiki/Parque_Nacional_do_Alto_Cariri` | No valor do atributo `href`. |

Quando quisermos o nome, extrairemos o texto. Quando quisermos visitar a página, extrairemos o atributo. Neste exemplo, o endereço já está pronto para ser utilizado: não precisamos acrescentar o domínio da Wikipedia.

O texto clicável também poderia ser “clique aqui” ou “saiba mais”. Não podemos deduzir o endereço a partir do texto mostrado ao leitor.

**Exercício:** Coloque o código completo da tag `a` no documento de página simples que você criou, salve e abra novamente no navegador. A seguir altere apenas a expressão `Alto Cariri`, mantendo o mesmo `href`. O destino do link mudou? Depois faça o contrário: altere o `href` para o endereço "https://www.pudim.com.br/" e mantenha o texto. Qual é o novo resultado?

## Endereços absolutos e relativos

No trecho da Wikipedia que acabamos de examinar, o `href` contém uma **URL absoluta**, isto é, um endereço completo. Mas nem todo `href` precisa estar escrito assim. Em outros sites, podemos encontrar um endereço relativo, como neste exemplo hipotético:

```html
<a href="/wiki/Parque_Nacional_do_Itatiaia">Itatiaia</a>
```

Esse é um endereço relativo. Ele precisa ser interpretado em relação ao endereço da página em que aparece. **Não é o formato do link do Alto Cariri que acabamos de observar**: usamos este segundo exemplo apenas para aprender outra possibilidade.

Se encontrássemos esse link em uma página do domínio `pt.wikipedia.org`, o navegador conseguiria completar o endereço. Em R, também podemos fazer essa operação com uma função apropriada.

Também podemos encontrar formas como `./Parque_Nacional_do_Itatiaia`, relativas ao caminho atual, ou links como `#Referencias`, que apontam para uma parte do próprio documento.

Guarde a ideia, não uma regra de juntar textos de qualquer jeito: **um endereço relativo depende de uma base**. No terceiro tutorial usaremos uma função para resolver isso. Ela também poderá receber endereços que já são absolutos, sem precisar modificá-los.

## `src`, `alt` e outros atributos

Uma imagem pode aparecer assim:

```html
<img src="foto-parque.jpg" alt="Uma paisagem de parque nacional">
```

`src` indica de onde carregar a imagem. `alt` contém uma alternativa textual para ela.

Não temos esse arquivo de imagem no tutorial: o exemplo serve apenas para reconhecer a marcação.

A lógica da extração é a mesma de `href`. Primeiro localizamos o elemento; depois escolhemos qual atributo queremos obter.

# Caminhos: encontrando informações na hierarquia

Agora estamos prontos para retomar nossa pergunta: como indicar em R exatamente o que queremos extrair?

Pense nos caminhos de pastas no computador. Para encontrar um arquivo, podemos indicar em qual pasta ele está, dentro de qual outra pasta, e assim por diante.

Em um documento estruturado também podemos descrever caminhos. Eles não são URLs: **não indicam o endereço de outra página, mas uma posição ou um conjunto de elementos dentro do documento**.

Vamos aprender duas formas de fazer isso: XPath e seletores CSS.

# XPath: caminhos entre elementos

XPath é uma linguagem para selecionar partes de documentos estruturados. Vamos utilizar apenas algumas formas simples de escrever esses caminhos.

No XML do início da atividade, o caminho para os nomes dos parques é:

```text
/parques/parque/nome
```

Podemos ler: comece na raiz do documento, encontre `parques`, entre em seus filhos `parque` e depois nos filhos `nome`.

O resultado não é necessariamente um único elemento. Neste exemplo, o caminho encontra dois nomes.

Para encontrar os estados, escrevemos:

```text
/parques/parque/estados/estado
```

Encontramos três elementos `estado`. O nome Rio de Janeiro aparece duas vezes porque está associado a dois parques diferentes.

## Uma barra e duas barras

Uma barra `/` separa etapas em que procuramos **filhos diretos**.

Duas barras `//` permitem procurar **descendentes**, sem escrever todos os níveis intermediários.

Por exemplo:

```text
//estado
```

Leia: encontre os elementos `estado` em qualquer ponto do documento.

Já:

```text
//parque//estado
```

Leia: encontre elementos `estado` que estejam dentro de algum `parque`, mesmo que existam outros níveis entre eles.

Compare com:

```text
//parque/estado
```

No nosso exemplo, esse último caminho não encontra nada. Por quê? Porque `estado` não é filho direto de `parque`; há um elemento `estados` entre eles.

Essa é uma das diferenças mais importantes desta atividade.

## Usando atributos como critérios

Na versão em que acrescentamos o atributo `sigla`, podemos selecionar apenas os estados com determinado valor:

```text
//estado[@sigla='RJ']
```

Vamos traduzir: encontre elementos `estado` cujo atributo `sigla` tenha o valor `RJ`.

Os colchetes delimitam uma condição. O símbolo `@` indica que estamos nos referindo a um atributo. As aspas indicam o texto que queremos encontrar.

É parecido, em intenção, com selecionar linhas usando um critério no `filter()`. Mas aqui ainda não estamos trabalhando com linhas de um data frame: estamos selecionando elementos de um documento.

No HTML, podemos aplicar a mesma ideia:

```text
//div[@id='itatiaia']//a
```

Encontramos os links que estão dentro do bloco cujo `id` é `itatiaia`.

**Obs.:** os colchetes fazem parte da sintaxe XPath. Eles não estão selecionando uma posição de um vetor de R. É importante reconhecer em qual linguagem estamos escrevendo.

## Começando por um elemento já selecionado

Mais adiante selecionaremos uma tabela e procuraremos links **dentro dela**.

Nesse caso, usaremos:

```text
.//a
```

O ponto `.` significa “a partir do elemento atual”.

Essa diferença evita procurar novamente no documento inteiro. Quando o ponto de partida é uma tabela já selecionada, `.//a` significa “os links dentro desta tabela”.

Pense nisso como começar uma busca dentro da pasta em que já estamos, em vez de começar novamente pela raiz do computador.

# Seletores CSS: outra forma de encontrar os mesmos elementos

CSS significa *Cascading Style Sheets*. É uma linguagem utilizada para definir a apresentação de documentos, como cores e tamanhos de fonte.

Mas, antes de aplicar uma aparência, uma regra CSS precisa identificar **a quais elementos ela se aplica**. Essa parte é o **seletor**.

Na raspagem, podemos aproveitar o seletor sem escrever nenhuma regra de aparência.

Você encontrará também a expressão *CSS path*. Aqui, ela se refere a um caminho ou combinação de seletores CSS para localizar elementos. Não é uma terceira linguagem diferente de CSS.

## Selecionando pelo nome da tag

Para encontrar todos os parágrafos, usamos:

```css
p
```

Para encontrar todos os links:

```css
a
```

Bastante simples, não?

## Descendentes e filhos diretos

Um espaço entre os nomes indica descendência:

```css
div a
```

Leia: encontre elementos `a` que estejam dentro de um `div`, mesmo que existam outros elementos no meio.

O símbolo `>` indica filho direto:

```css
div > a
```

Agora encontramos apenas elementos `a` cujo pai é um `div`.

Compare com nosso exemplo em que um link está dentro de um título:

```html
<div>
  <h2>
    <a href="https://pt.wikipedia.org/wiki/Parque_Nacional_do_Itatiaia">Itatiaia</a>
  </h2>
</div>
```

`div a` encontra o link. `div > a` não encontra, pois o pai direto de `a` é `h2`.

A diferença é a mesma que acabamos de estudar com uma e duas barras no XPath, embora os símbolos sejam outros.

## Selecionando por `id`, `class` e atributo

Para selecionar pelo `id`, usamos `#`:

```css
#itatiaia
```

Para selecionar por uma classe, usamos `.`:

```css
.parque
```

Para selecionar links dentro dos elementos dessa classe:

```css
.parque a
```

O seletor `.parque` encontra também um elemento com `class="parque destaque"`. Ele procura a classe dentro do conjunto de classes do elemento.

Também podemos escrever uma condição sobre um atributo:

```css
estado[sigla="RJ"]
```

Ou selecionar os elementos que possuem um atributo, independentemente de seu valor:

```css
a[href]
```

Neste último caso, selecionamos os elementos `a` que têm `href`.

Não misture os símbolos das duas linguagens: XPath usa `@` para atributos; o seletor CSS acima não usa.

## Comparando as duas maneiras

Vamos organizar alguns exemplos lado a lado:

| O que queremos | XPath | Seletor CSS |
|:---|:---|:---|
| Todos os parágrafos | `//p` | `p` |
| Todos os links | `//a` | `a` |
| Links dentro de algum `div` | `//div//a` | `div a` |
| Links que são filhos diretos de `div` | `//div/a` | `div > a` |
| Elemento com `id="itatiaia"` | `//*[@id='itatiaia']` | `#itatiaia` |
| Estados com `sigla="RJ"` | `//estado[@sigla='RJ']` | `estado[sigla="RJ"]` |
| Links dentro do bloco Itatiaia | `//*[@id='itatiaia']//a` | `#itatiaia a` |

O asterisco `*` significa “qualquer nome de elemento”. Em `//*[@id='itatiaia']`, não exigimos que o elemento seja um `div`.

**Atenção:** o ponto de `.parque`, em CSS, indica uma classe. O ponto de `.//a`, em XPath, indica o elemento atual. O símbolo se parece, mas a função é diferente.

Não precisamos escolher uma linguagem para a vida toda. Precisamos saber escrever um caminho que encontre o que queremos e conferir o resultado.

# Armazenando HTML em R

Vamos agora experimentar com um documento que conhecemos por inteiro.

Começamos chamando os pacotes. Caso não estejam instalados, use os comandos de instalação do primeiro tutorial.

```{r carregar-pacotes}
library(rvest)
library(tidyverse)
```

Vamos guardar um pequeno HTML em um objeto de texto:

```{r criar-html-exemplo}
html_exemplo <- '
<!DOCTYPE html>
<html lang="pt-BR">
  <head>
    <meta charset="UTF-8">
    <title>Parques nacionais</title>
  </head>
  <body>
    <h1>Nossa lista de parques</h1>
    <div id="lista-parques">
      <div id="itatiaia" class="parque">
        <h2>
          <a href="https://pt.wikipedia.org/wiki/Parque_Nacional_do_Itatiaia">Itatiaia</a>
        </h2>
        <p class="descricao">Texto didático sobre Itatiaia.</p>
      </div>
      <div id="tijuca" class="parque destaque">
        <h2>
          <a href="https://pt.wikipedia.org/wiki/Parque_Nacional_da_Tijuca">Tijuca</a>
        </h2>
        <p class="descricao">Texto didático sobre a Tijuca.</p>
      </div>
    </div>
    <p>
      <a href="https://pt.wikipedia.org/">Página inicial da Wikipedia</a>
    </p>
  </body>
</html>'
```

O texto inteiro está entre aspas simples. Dentro dele, usamos aspas duplas nos atributos. Isso evita fechar o texto de R sem querer.

Note também que os dois links dos parques foram escritos com **URLs absolutas**, como no trecho da Wikipedia que examinamos. Nosso HTML é um exemplo didático, mas agora reproduz essa característica dos endereços.

Até agora, `html_exemplo` é apenas um objeto da classe `character`, assim como a URL do primeiro tutorial.

Vamos interpretá-lo como HTML:

```{r ler-html-exemplo}
pagina_exemplo <- read_html(html_exemplo)

class(html_exemplo)
class(pagina_exemplo)
```

A mesma função pode receber o HTML escrito em um texto. Neste caso, ela **não precisa acessar a internet**, pois já fornecemos o conteúdo.

## Primeiro selecionamos os elementos

A função `html_elements()` seleciona os elementos HTML que correspondem a um caminho. Podemos escrever esse caminho como um seletor CSS ou como um XPath.

Vamos começar por todos os links:

```{r selecionar-todos-os-links}
elementos_links_pagina <- pagina_exemplo %>%
  html_elements(css = "a")

elementos_links_pagina
length(elementos_links_pagina)
```

Encontramos três elementos.

O resultado ainda não é um vetor de endereços. É um conjunto de **elementos HTML**: neste caso, os três elementos `a` encontrados no documento.

É importante separar essas operações: primeiro **selecionamos os elementos** com `html_elements()`; depois **extraímos as informações** que queremos guardar, como o texto ou os valores dos atributos.

## Selecionando apenas os links dos parques

Não queremos o link para a página inicial da Wikipedia. Como podemos deixá-lo de fora?

Os dois links que nos interessam estão dentro do elemento com `id="lista-parques"`. Vamos usar essa informação:

```{r selecionar-links-xpath}
elementos_links_parques <- pagina_exemplo %>%
  html_elements(xpath = "//div[@id='lista-parques']//a")

length(elementos_links_parques)
elementos_links_parques
```

Agora encontramos dois elementos.

Podemos obter o mesmo resultado com CSS:

```{r selecionar-links-css}
elementos_links_parques_css <- pagina_exemplo %>%
  html_elements(css = "#lista-parques a")

length(elementos_links_parques_css)
```

Note os argumentos: `xpath` recebe um XPath; `css` recebe um seletor CSS. Não passamos os dois ao mesmo tempo.

Não estamos navegando para outra página. Estamos apenas escolhendo partes do documento que já está em `pagina_exemplo`.

## Extraindo texto e atributos

Para obter o texto dos elementos, usamos `html_text()`:

```{r extrair-nomes}
nomes_parques <- elementos_links_parques %>%
  html_text()

nomes_parques
```

O resultado é um vetor com `Itatiaia` e `Tijuca`.

Para obter os endereços, usamos `html_attr()`:

```{r extrair-enderecos}
enderecos_parques <- elementos_links_parques %>%
  html_attr("href")

enderecos_parques
```

Agora temos os valores de `href`, não os textos clicáveis.

Vamos colocar as duas informações lado a lado:

```{r montar-tabela-de-links}
tabela_links_parques <- tibble(
  nome_parque = nomes_parques,
  endereco = enderecos_parques
)

tabela_links_parques
```

Excelente! Construímos um data frame a partir de informações que **não estavam organizadas em uma tabela HTML**.

Os vetores correspondem entre si porque foram extraídos do mesmo conjunto de elementos, na mesma ordem. Não basta dois vetores terem o mesmo tamanho: precisamos garantir que cada nome está ao lado do endereço correto.

## Extraindo apenas os parágrafos de descrição

Vamos fazer mais uma operação:

```{r extrair-descricoes}
descricoes <- pagina_exemplo %>%
  html_elements(css = "p.descricao") %>%
  html_text()

descricoes
```

`p.descricao` significa “elementos `p` que têm a classe `descricao`”. Não é o mesmo que `p .descricao`, com espaço, que procuraria descendentes dentro de `p`.

Leia o código: começamos pelo documento, selecionamos os parágrafos desejados e extraímos o texto.

Já temos a lógica que usaremos na Wikipedia.

# Da página didática para uma página real

Abra novamente a lista de parques nacionais da Wikipedia. Posicione o mouse sobre um nome de parque, clique com o botão direito e escolha **Inspecionar**.

O navegador mostrará a estrutura correspondente ao elemento. Procure uma marcação `a` e examine seu `href`.

Depois observe os elementos ao redor: o link está dentro de uma célula? A célula está dentro de uma linha? Há um `tbody` entre as linhas e a tabela?

Podemos começar pelo elemento que queremos e subir na hierarquia para identificar um caminho.

Os navegadores também costumam oferecer opções para copiar um XPath ou um seletor. Elas podem ajudar, mas não substituem a leitura da estrutura. Um caminho cheio de posições numéricas pode deixar de funcionar quando outro elemento é inserido na página.

**Não existe um caminho que sirva para todos os sites.** Nosso objetivo é compreender como construir e conferir um caminho adequado.

## Um cuidado com o que aparece no navegador

A ferramenta de inspeção mostra a estrutura que o navegador está utilizando. Em algumas páginas, parte do conteúdo é acrescentada ou modificada depois do carregamento, por JavaScript.

Já `read_html()` trabalha com o HTML recebido na solicitação; não executa esses programas como um navegador completo.

Por isso, ver uma informação na tela não garante que ela esteja no documento recebido pelo R. Nesta sequência estamos aprendendo a raspagem de HTML estático. Resolver páginas que dependem de interações e conteúdo dinâmico é outro problema.

# Para praticar antes de avançar

Volte ao objeto `html_exemplo` e faça pequenas alterações. Depois execute novamente `read_html()` para que elas apareçam em `pagina_exemplo`.

**Primeiro exercício:** acrescente um terceiro bloco de parque dentro de `lista-parques`. Use um nome fictício e deixe isso explícito no texto. Quantos links o seletor `#lista-parques a` encontra agora?

**Segundo exercício:** encontre apenas o link do bloco `tijuca`. Escreva uma solução em XPath e outra em CSS. Compare os textos e os atributos extraídos.

**Terceiro exercício:** troque a classe de um parágrafo de `descricao` para `observacao`. O que muda no resultado de `p.descricao`?

O importante não é acertar de primeira. É conseguir explicar por que um elemento foi encontrado ou ficou de fora.

Na próxima atividade voltaremos à Wikipedia. Vamos extrair os links dos parques, capturar o texto de uma página e, só depois, aprender a repetir a operação com um **for loop**.


# [Extra] Experimentando XPath também no XML

Podemos verificar os caminhos XML com um exemplo igualmente pequeno. Este trecho é uma atividade complementar; não é necessário para executar o terceiro tutorial.

Vamos usar a versão com os atributos `sigla`:

```{r criar-xml-exemplo}
xml_exemplo <- '
<parques>
  <parque>
    <nome>Itatiaia</nome>
    <estados>
      <estado sigla="MG">Minas Gerais</estado>
      <estado sigla="RJ">Rio de Janeiro</estado>
    </estados>
  </parque>
  <parque>
    <nome>Tijuca</nome>
    <estados>
      <estado sigla="RJ">Rio de Janeiro</estado>
    </estados>
  </parque>
</parques>'
```

O pacote *xml2*, instalado como dependência do *rvest*, contém funções para ler XML e selecionar seus elementos.

A escrita `xml2::read_xml()` significa “use a função `read_xml()` do pacote *xml2*”. Os dois-pontos duplos permitem indicar o pacote sem chamar `library(xml2)`.

```{r ler-xml-exemplo}
documento_xml <- xml2::read_xml(xml_exemplo)
```

Agora vamos selecionar os estados:

```{r selecionar-estados-xml}
elementos_estados <- xml2::xml_find_all(
  documento_xml,
  "/parques/parque/estados/estado"
)

xml2::xml_text(elementos_estados)
```

`xml_find_all()` seleciona os elementos indicados pelo caminho; `xml_text()` extrai o texto desses elementos. Reconhece a lógica? É a mesma separação entre selecionar e extrair que acabamos de praticar no HTML.

Vamos usar um atributo:

```{r selecionar-rj-xml}
elementos_estados_rj <- xml2::xml_find_all(
  documento_xml,
  "//estado[@sigla='RJ']"
)

xml2::xml_text(elementos_estados_rj)
```

O resultado contém Rio de Janeiro duas vezes. Não é um erro de duplicação da função: há dois elementos distintos com esse conteúdo no documento.

E o que acontece com este caminho?

```{r comparar-filhos-diretos}
xml2::xml_find_all(documento_xml, "//parque/estado")
```

Nenhum elemento é encontrado. Falta atravessar o nível `estados`, ou usar `//` para procurar descendentes.

Pronto! Agora não estamos apenas lendo os caminhos: verificamos o que eles encontram.
