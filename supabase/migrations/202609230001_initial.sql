create extension if not exists pgcrypto;

create table public.estabelecimentos (
 id uuid primary key default gen_random_uuid(), proprietario_id uuid not null references auth.users(id), nome text not null check (length(trim(nome)) between 2 and 100), slug text not null unique check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'), descricao text default '', logo_url text, capa_url text, cor_principal text not null default '#cb5b38' check (cor_principal ~ '^#[0-9a-fA-F]{6}$'), telefone text, endereco text, redes jsonb not null default '{}'::jsonb, fuso text not null default 'America/Sao_Paulo', fechado_hoje boolean not null default false, aviso text, aviso_ativo boolean not null default false, aviso_ate timestamptz, created_at timestamptz not null default now()
);
create table public.usuarios (
 id uuid primary key references auth.users(id) on delete cascade, estabelecimento_id uuid not null references public.estabelecimentos(id) on delete cascade, papel text not null default 'gerente' check (papel in ('proprietario','gerente')),
 unique(id, estabelecimento_id)
);
create table public.categorias (
 id uuid primary key default gen_random_uuid(), estabelecimento_id uuid not null references public.estabelecimentos(id) on delete cascade, nome text not null check (length(trim(nome)) > 0), ordem int not null default 0, visivel boolean not null default true,
 unique(id, estabelecimento_id)
);
create table public.produtos (
 id uuid primary key default gen_random_uuid(), estabelecimento_id uuid not null references public.estabelecimentos(id) on delete cascade, categoria_id uuid not null, nome text not null check (length(trim(nome)) > 0), descricao text not null default '', preco_centavos int not null check (preco_centavos >= 0), preco_promocional_centavos int check (preco_promocional_centavos >= 0), foto_url text, video_url text, video_poster_url text, altura_cm numeric(8,2), largura_cm numeric(8,2), comprimento_cm numeric(8,2), peso_g numeric(10,2), volume_ml numeric(10,2), serve_pessoas int, alergenos text, ingredientes text, combo_itens text[] not null default '{}', selos text[] not null default '{}', status text not null default 'ativo' check (status in ('ativo','pausado')), dias_disponiveis int[], inicio_disponibilidade time, fim_disponibilidade time, ordem int not null default 0, created_at timestamptz not null default now(),
 foreign key (categoria_id, estabelecimento_id) references public.categorias(id, estabelecimento_id)
);
create table public.midias (
 id uuid primary key default gen_random_uuid(), estabelecimento_id uuid not null references public.estabelecimentos(id) on delete cascade, produto_id uuid, tipo text not null check (tipo in ('foto','video','poster','logo','capa')), url text not null, created_at timestamptz not null default now(),
 foreign key (produto_id, estabelecimento_id) references public.produtos(id, estabelecimento_id)
);
create table public.horarios (
 id uuid primary key default gen_random_uuid(), estabelecimento_id uuid not null references public.estabelecimentos(id) on delete cascade, dia_semana int not null check (dia_semana between 0 and 6), abre time not null, fecha time not null, check (abre < fecha)
);
create table public.excecoes_horario (
 id uuid primary key default gen_random_uuid(), estabelecimento_id uuid not null references public.estabelecimentos(id) on delete cascade, data date not null, fechado boolean not null default true, abre time, fecha time, check (fechado or (abre is not null and fecha is not null and abre < fecha))
);
create table public.mesas (
 id uuid primary key default gen_random_uuid(), estabelecimento_id uuid not null references public.estabelecimentos(id) on delete cascade, numero text not null check (length(trim(numero)) > 0), unique(estabelecimento_id, numero)
);

create index on public.categorias(estabelecimento_id, ordem);
create index on public.produtos(estabelecimento_id, categoria_id, ordem);
create index on public.horarios(estabelecimento_id, dia_semana);

create function public.meu_estabelecimento() returns uuid language sql stable security definer set search_path = '' as $$ select estabelecimento_id from public.usuarios where id = (select auth.uid()) limit 1 $$;
create function public.criar_estabelecimento(p_nome text, p_slug text) returns uuid language plpgsql security definer set search_path = '' as $$
declare v_id uuid;
begin
 if auth.uid() is null then raise exception 'Autenticação obrigatória'; end if;
 if exists(select 1 from public.usuarios where id = auth.uid()) then raise exception 'Conta já vinculada'; end if;
 insert into public.estabelecimentos(proprietario_id,nome,slug) values(auth.uid(),trim(p_nome),lower(trim(p_slug))) returning id into v_id;
 insert into public.usuarios(id,estabelecimento_id,papel) values(auth.uid(),v_id,'proprietario');
 return v_id;
end $$;
revoke all on function public.criar_estabelecimento(text,text) from public;
grant execute on function public.criar_estabelecimento(text,text) to authenticated;

alter table public.estabelecimentos enable row level security;
alter table public.usuarios enable row level security;
alter table public.categorias enable row level security;
alter table public.produtos enable row level security;
alter table public.midias enable row level security;
alter table public.horarios enable row level security;
alter table public.excecoes_horario enable row level security;
alter table public.mesas enable row level security;

create policy estabelecimento_publico on public.estabelecimentos for select to anon,authenticated using (true);
create policy estabelecimento_editar on public.estabelecimentos for update to authenticated using (id = public.meu_estabelecimento()) with check (id = public.meu_estabelecimento() and proprietario_id = auth.uid());
create policy usuario_ler on public.usuarios for select to authenticated using (id = auth.uid());

create policy categorias_ler on public.categorias for select to anon,authenticated using (visivel or estabelecimento_id = public.meu_estabelecimento());
create policy categorias_inserir on public.categorias for insert to authenticated with check (estabelecimento_id = public.meu_estabelecimento());
create policy categorias_editar on public.categorias for update to authenticated using (estabelecimento_id = public.meu_estabelecimento()) with check (estabelecimento_id = public.meu_estabelecimento());
create policy categorias_excluir on public.categorias for delete to authenticated using (estabelecimento_id = public.meu_estabelecimento());

create policy produtos_ler on public.produtos for select to anon,authenticated using ((status = 'ativo' and exists(select 1 from public.categorias c where c.id = categoria_id and c.visivel)) or estabelecimento_id = public.meu_estabelecimento());
create policy produtos_inserir on public.produtos for insert to authenticated with check (estabelecimento_id = public.meu_estabelecimento());
create policy produtos_editar on public.produtos for update to authenticated using (estabelecimento_id = public.meu_estabelecimento()) with check (estabelecimento_id = public.meu_estabelecimento());
create policy produtos_excluir on public.produtos for delete to authenticated using (estabelecimento_id = public.meu_estabelecimento());

create policy midias_ler on public.midias for select to anon,authenticated using (produto_id is null or exists(select 1 from public.produtos p where p.id = produto_id) or estabelecimento_id = public.meu_estabelecimento());
create policy midias_inserir on public.midias for insert to authenticated with check (estabelecimento_id = public.meu_estabelecimento());
create policy midias_excluir on public.midias for delete to authenticated using (estabelecimento_id = public.meu_estabelecimento());

create policy horarios_ler on public.horarios for select to anon,authenticated using (true);
create policy horarios_inserir on public.horarios for insert to authenticated with check (estabelecimento_id = public.meu_estabelecimento());
create policy horarios_excluir on public.horarios for delete to authenticated using (estabelecimento_id = public.meu_estabelecimento());
create policy excecoes_ler on public.excecoes_horario for select to anon,authenticated using (true);
create policy excecoes_inserir on public.excecoes_horario for insert to authenticated with check (estabelecimento_id = public.meu_estabelecimento());
create policy excecoes_excluir on public.excecoes_horario for delete to authenticated using (estabelecimento_id = public.meu_estabelecimento());
create policy mesas_ler on public.mesas for select to authenticated using (estabelecimento_id = public.meu_estabelecimento());
create policy mesas_inserir on public.mesas for insert to authenticated with check (estabelecimento_id = public.meu_estabelecimento());
create policy mesas_excluir on public.mesas for delete to authenticated using (estabelecimento_id = public.meu_estabelecimento());

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values('cardapio','cardapio',true,31457280,array['image/jpeg','image/png','image/webp','video/mp4','video/webm']) on conflict (id) do nothing;
create policy midia_publica on storage.objects for select to anon,authenticated using (bucket_id = 'cardapio');
create policy midia_upload on storage.objects for insert to authenticated with check (bucket_id = 'cardapio' and (storage.foldername(name))[1] = public.meu_estabelecimento()::text);
create policy midia_remover on storage.objects for delete to authenticated using (bucket_id = 'cardapio' and (storage.foldername(name))[1] = public.meu_estabelecimento()::text);
