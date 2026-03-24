# HL7 PT — FHIR Implementation Guide Template

Este IG serve de template para novos IGs no ecossistema Português.

---

## Pré-requisitos

- **Docker Desktop** — [download para Mac / Windows / Linux](https://www.docker.com/products/docker-desktop/)
- Alternativa sem Docker: `java`, `ruby`, `jekyll` e `perl` instalados (ver modos abaixo)

---

## Publicar o IG

O comando é sempre o mesmo, independentemente do ambiente:

### 1. Dar permissão ao script (só na primeira vez)

```bash
chmod +x _genonce.sh
```

### 2. Correr o publisher

```bash
./_genonce.sh
```

> **Nota:** Se não houver ligação à internet, o script deteta isso automaticamente e corre em modo offline (sem validação de terminologias).

### 3. Ver o resultado no browser

**Opção simples:** abre o ficheiro `output/index.html` diretamente no browser.

**Opção com servidor local** (recomendado — alguns recursos podem não carregar sem servidor HTTP):

```bash
python3 -m http.server 8080 -d ./output
```

Abre [http://localhost:8080](http://localhost:8080) no browser.

Alternativas:

```bash
# Node.js
npx serve ./output

# Ruby
ruby -run -e httpd ./output -p 8080
```

---

## Como o script escolhe o modo de execução

O script `_genonce.sh` deteta automaticamente o melhor modo disponível, por esta ordem:

### Modo 1 — Java nativo (mais rápido)

**Condições:** `publisher.jar` encontrado + `java`, `ruby`, `jekyll` e `perl` instalados.

```text
./input-cache/publisher.jar   ou   ../publisher.jar
```

Corre diretamente com `java -jar`, sem Docker.

---

### Modo 2 — Docker com jar local (versão controlada)

**Condições:** `publisher.jar` encontrado, mas alguma dependência nativa em falta.

Usa a imagem `ghcr.io/fhir/ig-publisher-base` (apenas o runtime Java) e monta o jar local dentro do container. Permite controlar exatamente qual versão do [IG Publisher](https://github.com/HL7/fhir-ig-publisher/releases) é usada.

Para obter o `publisher.jar`, corre:

```bash
./_updatePublisher.sh
```

---

### Modo 3 — Docker com imagem completa (sem pré-requisitos)

**Condições:** nenhum `publisher.jar` encontrado.

Usa a imagem `ghcr.io/trifork/ig-publisher:latest`, que já inclui Java e o [IG Publisher](https://github.com/HL7/fhir-ig-publisher/releases). Não é necessário instalar nada além do Docker.

**Pré-requisito:** [Docker Desktop](https://www.docker.com/products/docker-desktop/) instalado e em execução.

Na primeira execução, o Docker faz download da imagem (~500 MB). As seguintes são muito mais rápidas.

---

## Cache de pacotes FHIR (`~/.fhir`)

Nos modos Docker, a pasta `~/.fhir` do host é montada no container. Esta pasta contém os pacotes FHIR descarregados (dependências do IG), pelo que não são repetidamente descarregados a cada execução.

---

## Atualizar o publisher

**Modo 3 (Docker):** para usar a versão mais recente basta fazer pull da imagem:

```bash
docker pull ghcr.io/trifork/ig-publisher:latest
```

**Modos 1 e 2 (jar local):** corre o script de atualização, que descarrega a versão mais recente do [IG Publisher](https://github.com/HL7/fhir-ig-publisher/releases):

```bash
./_updatePublisher.sh
```

---

## Estrutura do projeto

| Pasta / Ficheiro | Conteúdo |
| --- | --- |
| `input/fsh/` | Recursos em FHIR ShortHand (FSH) |
| `input/pagecontent/` | Páginas narrativas em Markdown |
| `input/images/` | Imagens |
| `input/images-source/` | Diagramas PlantUML |
| `input/examples/` | Exemplos em JSON |
| `input-cache/publisher.jar` | Publisher local (opcional, para modos 1 e 2) |
| `sushi-config.yaml` | Configuração do IG (páginas, menu, metadados) |
| `ig.ini` | Configuração do publisher |
| `output/` | Site gerado (criado ao correr o publisher) |

---

## Resolução de problemas

**"docker: command not found"**
→ Instala o [Docker Desktop](https://www.docker.com/products/docker-desktop/) e certifica-te que está em execução.

**"permission denied" ao correr o script**
→ Corre `chmod +x _genonce.sh` primeiro.

**Erro de terminologia / validação**
→ Se estiveres offline, o script deteta isso e usa `-tx n/a` automaticamente. Se estiveres online e o erro persistir, podes forçar o modo offline:

```bash
./_genonce.sh -tx n/a
```

**Conflito de versão do publisher (modo 3)**
→ Para fixar uma versão específica, edita `_genonce.sh` e substitui `latest` pela tag desejada, por exemplo `ghcr.io/trifork/ig-publisher:v1.6.x`.

**O modo nativo falha mas Java está instalado**
→ Verifica se `ruby`, `jekyll` e `perl` também estão instalados. Se algum faltar, o script usa Docker automaticamente.
