# HL7 PT — FHIR Implementation Guide Template

Este IG serve de template para novos IGs no ecossistema Português.

---

## Pré-requisitos

- **Docker Desktop** — [download para Mac / Windows / Linux](https://www.docker.com/products/docker-desktop/)
- Alternativa sem Docker: `java`, `ruby`, `jekyll` e `perl` instalados (ver modos abaixo)

---

## Publicar o IG

### macOS / Linux

#### 1. Dar permissão ao script (só na primeira vez)

```bash
chmod +x _genonce.sh
```

#### 2. Correr o publisher

```bash
./_genonce.sh
```

Para forçar um modo específico:

```bash
./_genonce.sh --mode 2   # Docker com jar local
./_genonce.sh --mode 3   # Docker com imagem completa
```

---

### Windows

Fazer duplo clique em `_genonce.bat`, ou correr na linha de comandos:

```bat
_genonce.bat
```

Para forçar um modo específico:

```bat
_genonce.bat --mode 2
_genonce.bat --mode 3
```

> **Nota Windows:** o Docker Desktop no Windows usa WSL2 e corre sempre containers `linux/amd64` nativamente — não são necessárias configurações adicionais.

---

> **Nota:** Se não houver ligação à internet, o script deteta isso automaticamente e corre em modo offline (sem validação de terminologias).

### 3. Ver o resultado no browser

**Opção simples:** abre o ficheiro `output/index.html` diretamente no browser.

**Opção com servidor local** (recomendado — alguns recursos podem não carregar sem servidor HTTP):

```bash
# macOS / Linux
python3 -m http.server 8080 -d ./output
```

```bat
REM Windows
python -m http.server 8080 -d output
```

Abre [http://localhost:8080](http://localhost:8080) no browser.

Alternativas:

```bash
# Node.js (todas as plataformas)
npx serve ./output

# Ruby (macOS / Linux)
ruby -run -e httpd ./output -p 8080
```

---

## Como o script escolhe o modo de execução

Os scripts `_genonce.sh` / `_genonce.bat` detetam automaticamente o melhor modo disponível, por esta ordem:

### Modo 1 — Java nativo (mais rápido)

**Condições:** `publisher.jar` encontrado + `java`, `ruby`, `jekyll` e `perl` instalados.

```text
./input-cache/publisher.jar   ou   ../publisher.jar
```

Corre diretamente com `java -jar`, sem Docker.

---

### Modo 2 — Docker com jar local (versão controlada)

**Condições:** `publisher.jar` encontrado, mas alguma dependência nativa em falta.

Usa a imagem `ghcr.io/trifork/ig-publisher:latest` como ambiente (Sushi, Node, etc.) mas executa o jar local em vez do bundled. Útil quando o jar local é mais recente do que o incluído na imagem.

Para obter o `publisher.jar`:

```bash
# macOS / Linux
./_updatePublisher.sh
```

```bat
REM Windows
_updatePublisher.bat
```

---

### Modo 3 — Docker com imagem completa (sem pré-requisitos)

**Condições:** nenhum `publisher.jar` encontrado.

Usa a imagem `ghcr.io/trifork/ig-publisher:latest`, que já inclui Java e o [IG Publisher](https://github.com/HL7/fhir-ig-publisher/releases). Não é necessário instalar nada além do Docker.

Na primeira execução, o Docker faz download da imagem (~500 MB). As seguintes são muito mais rápidas.

---

## Cache de pacotes FHIR

Nos modos Docker, a pasta de cache FHIR do host é montada no container, evitando downloads repetidos a cada execução.

| Plataforma | Pasta |
| --- | --- |
| macOS / Linux | `~/.fhir` |
| Windows | `%USERPROFILE%\.fhir` |

---

## Atualizar o publisher

**Modo 3 (Docker):** para usar a versão mais recente basta fazer pull da imagem:

```bash
docker pull ghcr.io/trifork/ig-publisher:latest
```

**Modos 1 e 2 (jar local):** corre o script de atualização, que descarrega a versão mais recente do [IG Publisher](https://github.com/HL7/fhir-ig-publisher/releases):

```bash
# macOS / Linux
./_updatePublisher.sh
```

```bat
REM Windows
_updatePublisher.bat
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

**"docker: command not found" / "docker não é reconhecido"**
→ Instala o [Docker Desktop](https://www.docker.com/products/docker-desktop/) e certifica-te que está em execução.

**"permission denied" ao correr o script (macOS/Linux)**
→ Corre `chmod +x _genonce.sh` primeiro.

**Erro de terminologia / validação**
→ Se estiveres offline, o script deteta isso e usa `-tx n/a` automaticamente. Se estiveres online e o erro persistir, podes forçar o modo offline:

```bash
# macOS / Linux
./_genonce.sh -tx n/a
```

```bat
REM Windows
_genonce.bat -tx n/a
```

**Conflito de versão do publisher (modo 3)**
→ Para fixar uma versão específica, substitui `latest` pela tag desejada nos scripts, por exemplo `ghcr.io/trifork/ig-publisher:v1.6.x`.

**O modo nativo falha mas Java está instalado**
→ Verifica se `ruby`, `jekyll` e `perl` também estão instalados. Se algum faltar, o script usa Docker automaticamente.
