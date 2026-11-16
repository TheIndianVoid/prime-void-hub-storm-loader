# Prime Void Hub — ajuste de escopo: somente Lotes 7 e 8

- Data: 2026-11-16.
- Correção expressa do usuário: **2 lotes**, não 3. Foram mantidos exclusivamente os **Lotes 7 e 8**, com 15 ports cada.
- Total após correção: **112 jogos registrados** (82 anteriores + 30 novos).
- Base dos arquivos de catálogo, checker, manifesto e README: commit de publicação concluída do **Lote 8** (`879c882c3014e7f00d05b555046a587007f48dd5`).
- Foram mantidos os **30 módulos Obscura VM completos** e reparados já presentes na `main`; os respectivos blobs Git SHA-1 atuais foram registrados no manifesto.
- Foram eliminadas as rotas, manifestos, arquivo de relatório e os 15 binários do **Lote 9**, cujo escopo foi retirado. O histórico Git preserva commits antigos (não é possível apagá-los sem reescrever a história), mas o `main` ativo não distribui nem anuncia esses 15 jogos.
- Foi retirado o workflow provisório de checagem de transporte, que não é necessário para operar os módulos já presentes no GitHub.
- **Teste real no Roblox:** pendente. Compilação Luau, proteção VM, integridade de arquivos e checagem de roteamento não garantem o efeito de cada funcionalidade em partida.

## Contagem de ports

| Fase | Novos | Acumulado |
|---|---:|---:|
| Lotes 1–6 | 82 já registrados | 82 |
| Lote 7 | 15 | 97 |
| Lote 8 | 15 | 112 |
| Lote 9 | **0 nesta autorização** | **112** |

Próxima publicação de ports somente com nova autorização explícita.
