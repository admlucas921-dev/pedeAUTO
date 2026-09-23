# PedeAUTO

Projeto inicial do cardápio digital multiempresa, com aplicativos separados para o cliente e o gerente. O painel já oferece login, cadastro, recuperação de senha e sessão autenticada pelo Supabase. O cardápio público lê os dados cadastrados e mostra categorias, produtos, horários e detalhes de cada item. A administração do catálogo ainda será acrescentada ao painel.

## Estrutura

- `apps/menu`: cardápio público em `/{slug}` e `/{slug}?mesa=12` (porta 5173).
- `apps/manager`: login e entrada no painel administrativo (porta 5174).
- `supabase/migrations`: modelo de dados e políticas RLS.

Os aplicativos são compilados e hospedados separadamente. Ambos usam o mesmo projeto Supabase. O menu é somente leitura; o banco impõe as regras de acesso. Não inclua uma chave `service_role` nem uma chave secreta no navegador.

## Configuração

1. Crie um projeto Supabase e execute `supabase/migrations/202609230001_initial.sql` no SQL Editor de um banco **novo**. Revise a migração antes de aplicá-la a um banco existente.
2. Copie `apps/menu/.env.example` para `apps/menu/.env.local` e `apps/manager/.env.example` para `apps/manager/.env.local`. Preencha a URL do projeto (`https://<ref>.supabase.co`) e sua chave pública (publishable/anon) em ambos. Em `VITE_MENU_URL`, informe a URL do cardápio publicado.
3. Em Supabase Auth > URL Configuration, cadastre a URL do painel em `Site URL` e em `Redirect URLs`; habilite autenticação por e-mail. A recuperação de senha usa esse redirecionamento. A redefinição efetiva da senha precisa de uma tela complementar, ainda pendente.
4. Execute `npm install`, `npm run dev:manager` e `npm run dev:menu` em terminais separados. Execute `npm run build` para conferir os dois aplicativos.
5. Publique cada pasta em um servidor distinto com suas próprias variáveis de ambiente. Configure fallback de rotas SPA para `index.html` no servidor do menu para permitir o acesso por slug.

## Primeira conta

No painel, clique em **Criar conta**, informe e-mail e senha, confirme o e-mail caso exigido e entre. A criação do estabelecimento e o formulário de cadastro de produtos ainda não foram conectados à interface. A função segura `criar_estabelecimento(nome, slug)` está pronta no banco para essa próxima etapa. Não há produtos fictícios nem estabelecimentos pré-cadastrados.

## Segurança e limites atuais

O banco usa `estabelecimento_id`, chaves compostas e políticas RLS para as tabelas principais. Uploads aceitam imagens JPEG, PNG ou WebP e vídeo MP4 ou WebM até 30 MB no bucket `cardapio`, restritos à pasta de cada estabelecimento. Os fluxos de upload, compressão de vídeo, poster, impressão de QR, cadastro administrativo e testes reais entre duas contas ainda precisam ser implementados e validados em um Supabase configurado. O vídeo exibido é uma filmagem giratória com medidas informadas pelo gerente; não existe reconstrução 3D nem garantia de proporção física na tela.
