# Captura de dados na internet com R

**cebrap.lab · Oficina virtual · Outubro de 2026**

Uma introdução prática à **raspagem de dados (*web scraping*) e ao uso de APIs com R**, voltada a estudantes e pesquisadores que desejam incorporar informações disponíveis na internet às suas pesquisas.

Ao longo de quatro atividades, vamos partir de uma tabela de parques nacionais na Wikipedia, conhecer a estrutura das páginas HTML, automatizar a coleta de textos e fazer nossas primeiras consultas à API de Dados Abertos da Câmara dos Deputados. O objetivo não é construir programas sofisticados, mas **entender cada etapa da coleta, examinar os resultados e organizar os dados para análise**.

**Navegação:** [Encontros](#encontros) · [Objetivos](#objetivos-de-aprendizagem) · [Atividades](#atividades-e-tutoriais) · [Como acompanhar](#como-acompanhar-o-curso)

---

## Encontros

| Encontro | Data | Horário | Instrutor |
|:---|:---|:---|:---|
| **1º encontro** | 19/10/2026 | 19h às 22h | Leonardo Sangali Barone |
| **2º encontro** | 20/10/2026 | 19h às 22h | Leonardo Sangali Barone |
| **3º encontro** | 22/10/2026 | 19h às 22h | Leonardo Sangali Barone |

**Modalidade:** virtual · **Horário:** de Brasília.

## Para quem é esta oficina?

O curso foi pensado para pessoas que já tiveram uma primeira introdução ao **R e ao RStudio**. Vamos presumir familiaridade com a criação de objetos, vetores, *data frames*, execução de comandos e operações básicas de manipulação de dados com *dplyr*, como `select()`, `filter()` e `mutate()`.

**Não é necessário conhecer previamente HTML, XML, JSON, XPath, raspagem de dados ou APIs.** Esses conceitos serão apresentados durante as atividades.

## Objetivos de aprendizagem

Ao final da oficina, esperamos que você consiga:

- Capturar informações de uma página da internet e transformá-las em *data frames* no R.
- Reconhecer elementos, atributos e a estrutura hierárquica de documentos HTML e XML.
- Usar XPath e seletores CSS para localizar informações e extrair textos e links.
- Utilizar `for loops` para repetir coletas e armazenar seus resultados.
- Compreender a estrutura de arquivos JSON e fazer consultas simples a uma API de dados abertos.
- Conferir os resultados da coleta e reconhecer os cuidados necessários ao trabalhar com fontes disponíveis na internet.

## Atividades e tutoriais

Os materiais estão na pasta **[`tutoriais/`](tutoriais/)** e foram preparados para serem realizados em sequência. Cada tutorial combina explicações, exemplos pequenos de código e exercícios para experimentar no RStudio.

### 01 · Nossa primeira raspagem: a tabela de parques nacionais

**[Abrir o Tutorial 1 — Capturando uma tabela na Wikipedia](tutoriais/01_capturando_tabela_parques.Rmd)**

Começaremos pela [lista de parques nacionais do Brasil na Wikipedia](https://pt.wikipedia.org/wiki/Lista_de_parques_nacionais_do_Brasil). Vamos acessar a página e transformar uma tabela HTML em um *data frame*, sem copiar e colar as informações manualmente.

**O que vamos aprender:** distinguir uma URL do conteúdo de uma página; capturar o HTML com `read_html()`; extrair tabelas com `html_table()`; examinar os resultados e escolher a tabela que nos interessa.

### 02 · Entendendo HTML, XML e os caminhos para encontrar informações

**[Abrir o Tutorial 2 — HTML, XML, XPath e seletores CSS](tutoriais/02_html_xml_xpath_css.Rmd)**

Antes de avançar na raspagem, vamos compreender como um documento organiza suas informações. Usaremos exemplos de parques, estados e trilhas para aprender a reconhecer elementos e hierarquias; depois criaremos uma pequena página HTML para praticar.

**O que vamos aprender:** identificar *tags*, conteúdo e atributos; entender como funcionam os links e o atributo `href`; construir caminhos XPath e seletores CSS; selecionar elementos com `html_elements()` e extrair texto ou atributos com `html_text()` e `html_attr()`.

### 03 · Dos links aos textos: automatizando a coleta

**[Abrir o Tutorial 3 — Raspagem de páginas com `for loops`](tutoriais/03_links_textos_for_loops.Rmd)**

Voltaremos à Wikipedia para extrair os endereços das páginas dos parques. Primeiro capturaremos os parágrafos de uma única página. Depois aprenderemos a repetir o procedimento e guardar os textos coletados em uma tabela.

**O que vamos aprender:** criar um vetor de endereços com `pull()`; extrair parágrafos com `html_elements(css = "p")`; juntar textos com `paste0()`; compreender os `for loops`; acumular observações com `tibble()` e `bind_rows()`; salvar os dados em CSV.

### 04 · Do HTML ao JSON: nossa primeira consulta a uma API

**[Abrir o Tutorial 4 — JSON e API da Câmara dos Deputados](tutoriais/04_json_primeira_api_camara.Rmd)**

Nem todos os dados precisam ser obtidos por raspagem de páginas HTML. Vamos recuperar os exemplos de parques e trilhas para compreender o formato JSON e, em seguida, consultar informações de Projetos de Lei (PLs) de 2025 na API de Dados Abertos da Câmara dos Deputados.

**O que vamos aprender:** reconhecer objetos e arrays em JSON; compreender APIs, *endpoints* e parâmetros de consulta; fazer uma requisição no R; transformar a resposta em um *data frame*; usar o identificador de uma proposição para consultar seus detalhes.

Essa última atividade prepara o terreno para um trabalho posterior com **documentos de inteiro teor e construção de um corpus de proposições legislativas**.

---

## Como acompanhar o curso

**1. Acesse os materiais.** Abra os tutoriais pelos links acima. Para trabalhar no seu computador, baixe os arquivos individualmente ou utilize **Code → Download ZIP**, no topo da página do repositório.

**2. Abra os arquivos no RStudio.** Os tutoriais estão escritos em **RMarkdown (`.Rmd`)**, formato que combina texto, explicações e blocos executáveis de R. O GitHub mostra esses arquivos como código-fonte; para executar os exemplos e acompanhar a aula, abra-os no RStudio.

**3. Execute os exercícios aos poucos.** Não é necessário executar o arquivo inteiro de uma vez. Leia as explicações, rode cada bloco de código e examine os objetos criados com funções como `head()`, `class()`, `str()` e `View()`.

### Pacotes necessários

Os principais pacotes utilizados são `rvest`, `tidyverse`, `jsonlite` e `httr2`. Caso ainda não estejam instalados, execute no R:

```r
install.packages(c("rvest", "tidyverse", "jsonlite", "httr2"))
```

Se também quiser gerar uma versão HTML de um tutorial pelo botão **Knit**, instale o pacote `rmarkdown`:

```r
install.packages("rmarkdown")
```

Algumas atividades acessam páginas e serviços externos e, portanto, exigem **conexão com a internet**. Como a estrutura das páginas e as respostas das APIs podem mudar, a conferência dos resultados faz parte do exercício. Coletas automatizadas devem respeitar as condições de acesso de cada fonte.

---

**Materiais do curso:** [pasta `tutoriais/`](tutoriais/) · **Repositório:** [cebrap-lab-raspagem-r-2026-virtual](https://github.com/leobarone/cebrap-lab-raspagem-r-2026-virtual)
