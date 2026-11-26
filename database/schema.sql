-- ConectaDoa — schema.sql
-- Cria o banco a partir do MER do PIE I (Usuario, Doador, Doacao, Categoria, Item e Doacao_Item).
-- Recria o banco do zero. Atenção: apaga os dados que já existirem. Use só em desenvolvimento.

SET NAMES utf8mb4;
DROP DATABASE IF EXISTS conectadoa;
CREATE DATABASE conectadoa CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE conectadoa;

-- Usuários que entram no sistema (coordenadores e voluntários).
-- A senha nunca é guardada em texto: só o hash (bcrypt), conforme o RNF4.
CREATE TABLE usuario (
  id_usuario  INT AUTO_INCREMENT PRIMARY KEY,
  nome        VARCHAR(150) NOT NULL,
  email       VARCHAR(100) NOT NULL UNIQUE,
  senha_hash  VARCHAR(255) NOT NULL,
  perfil      ENUM('coordenador', 'voluntario') NOT NULL DEFAULT 'voluntario',
  ativo       BOOLEAN NOT NULL DEFAULT TRUE,
  criado_em   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CHECK (TRIM(nome) <> ''),
  CHECK (email LIKE '%_@_%._%')
);

-- Pessoas e empresas que doam.
-- LGPD: o CPF do MER do PIE I ficou de fora. O MVP não tem uso para ele
-- (não há recibo fiscal), então a ONG não deve guardá-lo.
CREATE TABLE doador (
  id_doador     INT AUTO_INCREMENT PRIMARY KEY,
  nome          VARCHAR(150) NOT NULL,
  email         VARCHAR(100) UNIQUE,
  telefone      VARCHAR(20),
  ativo         BOOLEAN NOT NULL DEFAULT TRUE,
  data_cadastro TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CHECK (TRIM(nome) <> ''),
  CHECK (email IS NULL OR email LIKE '%_@_%._%')
);

-- Categorias do catálogo (Alimento, Higiene, Vestuário...).
CREATE TABLE categoria (
  id_categoria INT AUTO_INCREMENT PRIMARY KEY,
  nome         VARCHAR(80) NOT NULL UNIQUE,
  descricao    VARCHAR(255),
  ativa        BOOLEAN NOT NULL DEFAULT TRUE,
  CHECK (TRIM(nome) <> '')
);

-- Catálogo do que a ONG recebe. Relacionamento Categoria 1:N Item.
-- A quantidade recebida fica em doacao_item. O estoque é a soma dessas quantidades,
-- então não é guardado aqui, para não ficar desatualizado.
CREATE TABLE item (
  id_item      INT AUTO_INCREMENT PRIMARY KEY,
  id_categoria INT NOT NULL,
  nome         VARCHAR(150) NOT NULL,
  unidade      VARCHAR(20) NOT NULL DEFAULT 'unidade',
  prioridade   ENUM('baixa', 'media', 'alta') NOT NULL DEFAULT 'media',
  ativo        BOOLEAN NOT NULL DEFAULT TRUE,
  UNIQUE (id_categoria, nome),
  CHECK (TRIM(nome) <> ''),
  FOREIGN KEY (id_categoria) REFERENCES categoria (id_categoria)
);

-- Cada doação recebida. Relacionamento Doador 1:N Doacao.
-- Sem ON DELETE CASCADE: o banco impede excluir um doador que tem doações,
-- para o histórico da ONG não se perder.
CREATE TABLE doacao (
  id_doacao    INT AUTO_INCREMENT PRIMARY KEY,
  id_doador    INT NOT NULL,
  data_doacao  DATE NOT NULL,
  observacao   VARCHAR(255),
  status       ENUM('pendente', 'entregue', 'cancelada') NOT NULL DEFAULT 'pendente',
  data_entrega DATE,
  criado_em    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CHECK (data_entrega IS NULL OR data_entrega >= data_doacao),
  FOREIGN KEY (id_doador) REFERENCES doador (id_doador)
);

-- Tabela associativa do relacionamento N:N entre Doacao e Item.
-- A chave composta impede o mesmo item duas vezes na mesma doação.
-- Excluir a doação apaga os itens dela (ON DELETE CASCADE).
-- Um item que já aparece em doações não pode ser excluído (sem CASCADE).
CREATE TABLE doacao_item (
  id_doacao  INT NOT NULL,
  id_item    INT NOT NULL,
  quantidade INT NOT NULL CHECK (quantidade > 0),
  PRIMARY KEY (id_doacao, id_item),
  FOREIGN KEY (id_doacao) REFERENCES doacao (id_doacao) ON DELETE CASCADE,
  FOREIGN KEY (id_item) REFERENCES item (id_item)
);
