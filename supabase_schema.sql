-- =====================================================
-- ZAPFLOW - Schema Completo Açaí Brazuca
-- Cole e execute no Editor SQL do Supabase
-- =====================================================

-- 1. EMPRESAS
CREATE TABLE IF NOT EXISTS empresas (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  nome TEXT NOT NULL,
  email TEXT,
  telefone TEXT,
  endereco TEXT,
  cnpj TEXT,
  plano TEXT DEFAULT 'gratuito',
  logo_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. USUÁRIOS
CREATE TABLE IF NOT EXISTS usuarios (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  empresa_id UUID REFERENCES empresas(id) ON DELETE CASCADE,
  nome TEXT,
  email TEXT NOT NULL,
  role TEXT DEFAULT 'atendente' CHECK (role IN ('admin','atendente')),
  ativo BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. CLIENTES
CREATE TABLE IF NOT EXISTS clientes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  empresa_id UUID REFERENCES empresas(id) ON DELETE CASCADE NOT NULL,
  nome TEXT NOT NULL,
  telefone TEXT,
  email TEXT,
  endereco TEXT,
  observacoes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. CONVERSAS
CREATE TABLE IF NOT EXISTS conversas (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  empresa_id UUID REFERENCES empresas(id) ON DELETE CASCADE NOT NULL,
  cliente_id UUID REFERENCES clientes(id) ON DELETE CASCADE NOT NULL,
  status TEXT DEFAULT 'ativo',
  ultima_mensagem TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. MENSAGENS
CREATE TABLE IF NOT EXISTS mensagens (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  conversa_id UUID REFERENCES conversas(id) ON DELETE CASCADE NOT NULL,
  empresa_id UUID REFERENCES empresas(id) ON DELETE CASCADE NOT NULL,
  conteudo TEXT NOT NULL,
  remetente TEXT DEFAULT 'Atendente',
  tipo TEXT DEFAULT 'enviado',
  lida BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. PRODUTOS
CREATE TABLE IF NOT EXISTS produtos (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  empresa_id UUID REFERENCES empresas(id) ON DELETE CASCADE NOT NULL,
  nome TEXT NOT NULL,
  descricao TEXT,
  preco NUMERIC(10,2) NOT NULL DEFAULT 0,
  categoria TEXT DEFAULT 'Outros',
  ativo BOOLEAN DEFAULT TRUE,
  imagem_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. PEDIDOS
CREATE TABLE IF NOT EXISTS pedidos (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  empresa_id UUID REFERENCES empresas(id) ON DELETE CASCADE NOT NULL,
  cliente_id UUID REFERENCES clientes(id) ON DELETE SET NULL,
  status TEXT DEFAULT 'aberto',
  total NUMERIC(10,2) DEFAULT 0,
  observacoes TEXT,
  forma_pagamento TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. ITENS DO PEDIDO
CREATE TABLE IF NOT EXISTS itens_pedido (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  pedido_id UUID REFERENCES pedidos(id) ON DELETE CASCADE NOT NULL,
  empresa_id UUID REFERENCES empresas(id) ON DELETE CASCADE NOT NULL,
  produto_id UUID REFERENCES produtos(id) ON DELETE SET NULL,
  nome TEXT NOT NULL,
  quantidade INTEGER NOT NULL DEFAULT 1,
  preco_unitario NUMERIC(10,2) NOT NULL,
  observacao TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 9. FINANCEIRO
CREATE TABLE IF NOT EXISTS financeiro (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  empresa_id UUID REFERENCES empresas(id) ON DELETE CASCADE NOT NULL,
  pedido_id UUID REFERENCES pedidos(id) ON DELETE SET NULL,
  tipo TEXT NOT NULL CHECK (tipo IN ('receber','pagar')),
  descricao TEXT NOT NULL,
  valor NUMERIC(10,2) NOT NULL,
  status TEXT DEFAULT 'pendente',
  categoria TEXT,
  data_vencimento TIMESTAMPTZ,
  data_pagamento TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ÍNDICES
CREATE INDEX IF NOT EXISTS idx_clientes_empresa ON clientes(empresa_id);
CREATE INDEX IF NOT EXISTS idx_conversas_empresa ON conversas(empresa_id);
CREATE INDEX IF NOT EXISTS idx_mensagens_conversa ON mensagens(conversa_id);
CREATE INDEX IF NOT EXISTS idx_pedidos_empresa ON pedidos(empresa_id);
CREATE INDEX IF NOT EXISTS idx_itens_pedido ON itens_pedido(pedido_id);
CREATE INDEX IF NOT EXISTS idx_financeiro_empresa ON financeiro(empresa_id);
CREATE INDEX IF NOT EXISTS idx_produtos_empresa ON produtos(empresa_id);

-- =====================================================
-- ROW LEVEL SECURITY
-- =====================================================
ALTER TABLE empresas ENABLE ROW LEVEL SECURITY;
ALTER TABLE usuarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE clientes ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversas ENABLE ROW LEVEL SECURITY;
ALTER TABLE mensagens ENABLE ROW LEVEL SECURITY;
ALTER TABLE produtos ENABLE ROW LEVEL SECURITY;
ALTER TABLE pedidos ENABLE ROW LEVEL SECURITY;
ALTER TABLE itens_pedido ENABLE ROW LEVEL SECURITY;
ALTER TABLE financeiro ENABLE ROW LEVEL SECURITY;

-- Função auxiliar
CREATE OR REPLACE FUNCTION get_empresa_id()
RETURNS UUID AS $$
  SELECT empresa_id FROM usuarios WHERE id = auth.uid() LIMIT 1;
$$ LANGUAGE SQL SECURITY DEFINER STABLE;

-- Políticas por tabela
CREATE POLICY "emp_sel" ON empresas FOR SELECT USING (id = get_empresa_id());
CREATE POLICY "emp_upd" ON empresas FOR UPDATE USING (id = get_empresa_id());
CREATE POLICY "emp_ins" ON empresas FOR INSERT WITH CHECK (true);

CREATE POLICY "usr_sel" ON usuarios FOR SELECT USING (empresa_id = get_empresa_id() OR id = auth.uid());
CREATE POLICY "usr_ins" ON usuarios FOR INSERT WITH CHECK (true);
CREATE POLICY "usr_upd" ON usuarios FOR UPDATE USING (empresa_id = get_empresa_id());
CREATE POLICY "usr_del" ON usuarios FOR DELETE USING (empresa_id = get_empresa_id());

CREATE POLICY "cli_all" ON clientes FOR ALL USING (empresa_id = get_empresa_id()) WITH CHECK (empresa_id = get_empresa_id());
CREATE POLICY "conv_all" ON conversas FOR ALL USING (empresa_id = get_empresa_id()) WITH CHECK (empresa_id = get_empresa_id());
CREATE POLICY "msg_all" ON mensagens FOR ALL USING (empresa_id = get_empresa_id()) WITH CHECK (empresa_id = get_empresa_id());
CREATE POLICY "prod_all" ON produtos FOR ALL USING (empresa_id = get_empresa_id()) WITH CHECK (empresa_id = get_empresa_id());
CREATE POLICY "ped_all" ON pedidos FOR ALL USING (empresa_id = get_empresa_id()) WITH CHECK (empresa_id = get_empresa_id());
CREATE POLICY "item_all" ON itens_pedido FOR ALL USING (empresa_id = get_empresa_id()) WITH CHECK (empresa_id = get_empresa_id());
CREATE POLICY "fin_all" ON financeiro FOR ALL USING (empresa_id = get_empresa_id()) WITH CHECK (empresa_id = get_empresa_id());

-- REALTIME
ALTER PUBLICATION supabase_realtime ADD TABLE mensagens;
ALTER PUBLICATION supabase_realtime ADD TABLE pedidos;
ALTER PUBLICATION supabase_realtime ADD TABLE conversas;
