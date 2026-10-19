# Captura de dados na internet com R

**Oficina virtual · Outubro de 2026**

**Navegação:** [Encontros](#encontros) · [Objetivos](#objetivos-de-aprendizagem) · [Atividades](#atividades-e-tutoriais) · [Como acompanhar](#como-acompanhar-o-curso)

---

## Encontros

| Encontro | Data | Horário | Instrutor |
|:---|:---|:---|:---|
| **1º encontro** | 19/10/2026 | 19h às 22h | Leonardo Sangali Barone |
| **2º encontro** | 20/10/2026 | 19h às 22h | Leonardo Sangali Barone |
| **3º encontro** | 22/10/2026 | 19h às 22h | Leonardo Sangali Barone |

**Modalidade:** virtual · **Horário:** de Brasília.

## Objetivos do curso

O curso é uma introdução à **raspagem de dados (*web scraping*) e ao uso de APIs com R**, voltada a estudantes e pesquisadores. Nosso principal objetivo será construir conjuntos de dados e coleções de documentos usando programação computacional. Trabalharemos com páginas HTML, formulários de busca, respostas de APIs e arquivos PDF, sempre procurando compreender como as informações são obtidas e organizadas para a análise.

O curso foi pensado para pessoas que já tiveram uma primeira introdução ao **R e ao RStudio**. Vamos presumir familiaridade com a criação de objetos, vetores e *data frames*. Para retomar esses conhecimentos antes das atividades de coleta, faça o **Tutorial 0**, com exercícios introdutórios de manipulação de dados no *dplyr*. Ele pode ser realizado como preparação para a oficina ou utilizado para consulta ao longo dos encontros.

**Não é necessário conhecer previamente HTML, XML, JSON, XPath, raspagem de dados, formulários HTML ou APIs.** Esses conceitos serão apresentados durante as atividades.

## Objetivos de aprendizagem

Ao final da oficina, esperamos que você consiga:

- Capturar informações de uma página da internet e transformá-las em *data frames* no R.
- Reconhecer elementos, atributos e a estrutura hierárquica de documentos HTML e XML.
- Usar XPath e seletores CSS para localizar informações e extrair textos e links.
- Utilizar `for loops` para repetir coletas e armazenar seus resultados.
- Compreender a estrutura de arquivos JSON e fazer consultas simples a uma API de dados abertos.
- Identificar, preencher e enviar formulários HTML utilizando as funções atuais do pacote *rvest*.
- Baixar arquivos PDF, extrair seus textos e construir um *corpus* organizado em um *data frame*, associado aos metadados das proposições.
- Conferir os resultados da coleta e reconhecer os cuidados necessários ao trabalhar com fontes disponíveis na internet.

## Atividades e tutoriais

Os materiais estão na pasta **[`tutoriais/`](tutoriais/)**. São **sete tutoriais, numerados de 0 a 6**: o Tutorial 0 funciona como revisão inicial de R e *dplyr*; os Tutoriais 1 a 6 formam a sequência de raspagem, formulários, APIs e documentos. Cada atividade combina explicações, exemplos pequenos de código e exercícios para experimentar no RStudio.

### 00 · Preparação: primeiros passos no R e no dplyr

**[Tutorial 0 — Manipulando dados com dplyr](tutoriais/00_tutorial_inicial_r.Rmd)**

Antes de começar a coleta de informações pela internet, retomaremos os comandos básicos que serão utilizados em todo o curso. O exemplo utiliza o **Cadastro de escolas municipais, conveniadas e privadas da Prefeitura de São Paulo**, consultado diretamente por sua URL oficial, para praticar a manipulação de dados públicos reais.

**O que vamos aprender:** instalar e carregar pacotes; importar arquivos CSV com `read_csv2()`; distinguir objetos, vetores, colunas e linhas; explorar *data frames* com `head()`, `names()` e `glimpse()`; renomear, selecionar, transformar e filtrar variáveis com `dplyr`; encadear operações com `%>%`; obter contagens com `count()` e extrair vetores com `pull()`.

**Fonte dos dados:** [Cadastro de escolas municipais, conveniadas e privadas — Prefeitura de São Paulo](https://dados.prefeitura.sp.gov.br/dataset/cadastro-de-escolas-municipais-conveniadas-e-privadas). O Tutorial 0 lê o CSV diretamente da internet, portanto **não requer arquivo de dados local**. Sua execução depende de o endereço oficial estar acessível.

### 01 · Nossa primeira raspagem: a tabela de parques nacionais

**[Tutorial 1 — Capturando uma tabela na Wikipedia](tutoriais/01_capturando_tabela_parques.Rmd)**

Começaremos pela [lista de parques nacionais do Brasil na Wikipedia](https://pt.wikipedia.org/wiki/Lista_de_parques_nacionais_do_Brasil). Vamos acessar a página e transformar uma tabela HTML em um *data frame*, sem copiar e colar as informações manualmente.

**O que vamos aprender:** distinguir uma URL do conteúdo de uma página; capturar o HTML com `read_html()`; extrair tabelas com `html_table()`; examinar os resultados e escolher a tabela que nos interessa.

### 02 · Entendendo HTML, XML e os caminhos para encontrar informações

**[Tutorial 2 — HTML, XML, XPath e seletores CSS](tutoriais/02_html_xml_xpath_css.Rmd)**

Antes de avançar na raspagem, vamos compreender como um documento organiza suas informações. Aprenderemos a reconhecer elementos e hierarquias; depois criaremos uma pequena página HTML para praticar, utilizando exemplos de parques nacionais, estados e trilhas.

**O que vamos aprender:** identificar *tags*, conteúdo e atributos; entender como funcionam os links e o atributo `href`; construir caminhos XPath e seletores CSS; selecionar elementos com `html_elements()` e extrair texto ou atributos com `html_text()` e `html_attr()`.

### 03 · Dos links aos textos: automatizando a coleta

**[Tutorial 3 — Raspagem de páginas com `for loops`](tutoriais/03_links_textos_for_loops.Rmd)**

Voltaremos à Wikipedia para extrair os endereços das páginas dos parques. Primeiro capturaremos os parágrafos de uma única página. Depois aprenderemos a repetir o procedimento e guardar os textos coletados em uma tabela.

**O que vamos aprender:** criar um vetor de endereços com `pull()`; extrair parágrafos com `html_elements(css = "p")`; juntar textos com `paste0()`; compreender os `for loops`; acumular observações com `tibble()` e `bind_rows()`; salvar os dados em CSV.

### 04 · Do HTML ao JSON: nossa primeira consulta a uma API

**[Tutorial 4 — JSON e API da Câmara dos Deputados](tutoriais/04_json_primeira_api_camara.Rmd)**

Nem todos os dados precisam ser obtidos por raspagem de páginas HTML. Neste tutorial vamos compreender o formato JSON e, em seguida, consultar informações de Projetos de Lei (PLs) de 2025 na API de Dados Abertos da Câmara dos Deputados.

**O que vamos aprender:** reconhecer objetos e arrays em JSON; compreender APIs, *endpoints* e parâmetros de consulta; fazer uma requisição no R; transformar a resposta em um *data frame*; usar o identificador de uma proposição para consultar seus detalhes.

Retomaremos essas consultas no Tutorial 6, quando utilizaremos os endereços dos documentos de inteiro teor para construir uma coleção de textos legislativos. Antes disso, vamos conhecer outra forma de obter dados pela internet: os formulários HTML.

### 05 · Formulários na web: buscando teses e dissertações na BDTD

**[Tutorial 5 — Formulários na BDTD: resumos e metadados](tutoriais/05_formularios_bdtd_resumos_metadados.Rmd)**

Até aqui capturamos páginas e consultamos uma API. Agora vamos aprender a **preencher e enviar um formulário de busca**. Utilizaremos a [Biblioteca Digital Brasileira de Teses e Dissertações (BDTD)](https://bdtd.ibict.br/vufind/) para pesquisar teses e dissertações sobre um tema.

Depois de examinar o formulário e os resultados, visitaremos as páginas dos trabalhos encontrados para recuperar seus **resumos (*abstracts*) e metadados bibliográficos**. Cada linha do nosso *data frame* corresponderá a uma tese ou dissertação, e não a um artigo de periódico.

**O que vamos aprender:** reconhecer os elementos e campos de um formulário HTML; estabelecer uma sessão com `session()`; identificar, preencher e enviar formulários com `html_form()`, `html_form_set()` e `session_submit()`; extrair títulos, autoria, ano, instituição, tipo de documento, palavras-chave, resumos e links; repetir a coleta para vários registros e organizar um *corpus* de resumos.

Nesta atividade, nosso interesse está nos registros bibliográficos e nos resumos. **Não faremos o download dos documentos completos da BDTD.**

### 06 · Da API aos PDFs: construindo um corpus de proposições legislativas

**[Tutorial 6 — Da API da Câmara ao corpus de PDFs](tutoriais/06_api_camara_corpus_pdfs.Rmd)**

Na última atividade, retomaremos os Projetos de Lei de 2025 consultados no Tutorial 4. Vamos recuperar os detalhes de um pequeno conjunto de proposições, baixar os documentos de inteiro teor disponíveis em PDF e transformar seus conteúdos em uma tabela de textos para pesquisa. Partiremos de **uma proposição e um documento** antes de repetir a operação para vários casos.

**O que vamos aprender:** criar funções simples em R para consultar proposições e baixar arquivos; repetir consultas e registrar falhas; extrair textos de PDFs com `pdf_text()`; reunir as páginas de cada documento em um único texto; relacionar textos e metadados com `left_join()`; conferir a coleta e exportar o corpus em CSV.

Ao final, teremos os PDFs baixados e um pequeno *corpus* em que cada linha corresponde a um documento, incluindo seu `id`, informações da proposição e texto extraído. Também aprenderemos a identificar documentos que não puderam ser recuperados ou lidos.

---


## Pacotes necessários

Os principais pacotes utilizados são `tidyverse` (desde o Tutorial 0), `rvest`, `jsonlite`, `httr2` e `pdftools`. O pacote `pdftools` será utilizado no **Tutorial 6**, para a leitura dos PDFs. Caso ainda não estejam instalados, execute no R:

```r
install.packages(c("rvest", "tidyverse", "jsonlite", "httr2", "pdftools"))
```

Se também quiser gerar uma versão HTML de um tutorial pelo botão **Knit**, instale o pacote `rmarkdown`:

```r
install.packages("rmarkdown")
```

Algumas atividades acessam páginas e serviços externos e, portanto, exigem **conexão com a internet**. Como a estrutura das páginas e as respostas das APIs podem mudar, a conferência dos resultados faz parte do exercício. Coletas automatizadas devem respeitar as condições de acesso de cada fonte.

---

**Materiais do curso:** [pasta `tutoriais/`](tutoriais/) · **Repositório:** [cebrap-lab-raspagem-r-2026-virtual](https://github.com/leobarone/cebrap-lab-raspagem-r-2026-virtual)
