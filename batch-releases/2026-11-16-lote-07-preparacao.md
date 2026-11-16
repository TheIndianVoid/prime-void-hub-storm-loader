# Prime Void Hub — Lote 07 | preparação, NÃO publicado

- Data: 2026-11-16.
- Commit de referência: `d7b4735486e0092251af7f007b227a3bc67c6cc3`.
- Estado: **15 adaptations prepared privately; 0 Obscura VM binaries built; 0 gameplay ports activated**.
- O loader e o manifesto de produção permanecem com **82 jogos**. Nenhum candidato desta tabela foi acrescentado ao catálogo de jogos suportados.
- Foi gerado um pacote privado com 15 adapters de fontes sanitizadas, hashes SHA-256 conferidos, e um construtor Obscura VM que exige compilador Luau e Obscura fixados antes de permitir distribuição.
- **O código privado não está neste repositório público**. Não subir `private_adapted/` para a main.
- A inspeção estática não confirma funcionalidade em jogo ou identidade de scripts VM; jogos assinalados como potencialmente indisponíveis devem ser reconfirmados antes de publicar.

## Candidatos em preparação

| Nº | Nome-base | PlaceId | Slug da source | Pendência |
|---:|---|---|---|---|
| 1 | Steal a Mystery Egg | `137789242313999` | `steal-a-mystery-egg` | Needs VM build |
| 2 | Steal A Seed! | `122216176958450` | `steal-a-seed` | Needs VM; availability reported limited |
| 3 | Steal A Seed For Bees | `87026033799342` | `steal-a-seed-for-bees` | Needs VM; availability reported limited |
| 4 | Steal A Tree! | `132958491990446` | `steal-a-tree` | Needs VM build |
| 5 | Steal Anime Eggs | `96727061242653` | `steal-anime-eggs` | Needs VM; availability reported limited |
| 6 | Steal Anime Eggs & FIGHT! | `137671992254032` | `steal-anime-eggs-fight` | Needs VM build |
| 7 | Steal Brainrot Eggs | `104469958681645` | `steal-brainrot-eggs` | Needs VM build |
| 8 | Steal Fish Eggs | `99183404085821` | `steal-fish-eggs` | Needs VM build |
| 9 | Steal From The Rich! | `120475074479690` | `steal-from-the-rich` | Needs VM build |
| 10 | Steal The Museum | `88237852656234` | `steal-the-museum` | Needs VM build |
| 11 | Tap 4 Money | `125410772032969` | `tap-4-money` | Needs VM build |
| 12 | Zone Defense RNG | `71607575632633` | `zone-defense-rng` | Needs VM build |
| 13 | Fish an EGG from Rivers | `101672855717389` | `fish-an-egg-from-rivers` | Needs VM; availability reported limited |
| 14 | Merge & Dig Simulator! | `74569490529875` | `merge-dig-simulator` | Needs VM; availability reported limited |
| 15 | My Giant Farm | `98906051062892` | `my-giant-farm` | Needs VM; availability reported limited |

## Gates pendentes

1. Compilar cada adaptação com Luau no commit `f46d879e28302a430029304f7f6a162aed66f103`.
2. Proteger via Obscura VM no commit `742770554151d82c6a12ae6e24a0e47471bc467c`, sem publicar fontes em claro.
3. Compilar os módulos VM resultantes, conferir cabeçalho e hashes e executar testes em Roblox.
4. Confirmar PlaceId, nomes oficiais e disponibilidade de cada jogo. Retirar/repor candidatos não elegíveis antes de fechar 15.
5. Só então inserir rotas no `Loader.lua`, configurações, checker e logger; validar novamente a `main`.

**Importante:** esta nota é um registro de preparação, **não uma publicação do Lote 7**. Sem os builds protegidos não há autorização técnica para declarar mais jogos suportados.
