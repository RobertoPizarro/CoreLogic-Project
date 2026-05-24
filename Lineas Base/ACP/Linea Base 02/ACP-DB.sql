-- ============================================================
-- ACP — Script de Base de Datos
-- Base de datos: PostgreSQL (Supabase)
-- Moneda: Soles peruanos (S/)
-- Nota: auth.users es gestionada internamente por Supabase Auth.
--       Todas las FKs hacia usuarios referencian auth.users(id).
-- ============================================================


-- ============================================================
-- MÓDULO: AUTENTICACIÓN Y PERFIL
-- ============================================================

-- Tabla: profiles
-- Una fila por usuario. Almacena el nombre completo.
-- El correo se obtiene directamente del JWT de Supabase.
-- Relación: 1 auth.users → 1 profiles (uno a uno)
CREATE TABLE profiles (
    id          UUID        PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name   TEXT        NOT NULL,
    avatar_url  TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);


-- ============================================================
-- MÓDULO: INGRESOS, GASTOS PERSONALES Y PRESUPUESTOS
-- ============================================================

-- Tabla: categories
-- Categorías fijas predefinidas por la app. El usuario nunca las crea ni edita.
-- Se poblan una sola vez con el INSERT de seed al final del script.
-- Relación: 1 category → muchos movements
--           1 category → muchos budgets (solo tipo expense)
CREATE TABLE categories (
    id      UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    name    TEXT        NOT NULL,
    type    TEXT        NOT NULL CHECK (type IN ('income', 'expense')),
    icon    TEXT        NOT NULL
);

-- Tabla: movements (Movimientos personales)
-- Ingresos y gastos personales del usuario.
-- Completamente independiente del módulo de grupos.
-- Relación: muchos movements → 1 profiles (usuario dueño)
--           muchos movements → 1 categories
CREATE TABLE movements (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    type            TEXT        NOT NULL CHECK (type IN ('income', 'expense')),
    amount          NUMERIC(12, 2) NOT NULL CHECK (amount > 0),
    category_id     UUID        NOT NULL REFERENCES categories(id),
    date            DATE        NOT NULL,
    description     TEXT,
    payment_method  TEXT        NOT NULL CHECK (payment_method IN ('efectivo', 'tarjeta', 'transferencia')),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Tabla: budgets (Presupuestos personales)
-- Límite de gasto por categoría de tipo expense dentro de un período.
-- Solo puede existir un presupuesto por usuario + categoría en un rango de fechas dado.
-- Esa restricción de solapamiento se valida en el backend (no con constraint SQL).
-- Completamente independiente del módulo de grupos.
-- Relación: muchos budgets → 1 profiles (usuario dueño)
--           muchos budgets → 1 categories (solo tipo expense)
CREATE TABLE budgets (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    description TEXT        NOT NULL,
    amount      NUMERIC(12, 2) NOT NULL CHECK (amount > 0),
    category_id UUID        NOT NULL REFERENCES categories(id),
    start_date  DATE        NOT NULL,
    end_date    DATE        NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT end_after_start CHECK (end_date >= start_date)
);


-- ============================================================
-- MÓDULO: GRUPOS Y GASTOS COMPARTIDOS
-- ============================================================

-- Tabla: groups
-- Grupos de gastos compartidos.
-- Un usuario crea el grupo; múltiples usuarios pueden ser miembros.
-- No se pueden editar ni eliminar grupos (regla de negocio).
-- Relación: muchos groups → 1 profiles (creador)
--           1 group → muchos group_members
--           1 group → muchos group_expenses
--           1 group → muchos payments
CREATE TABLE groups (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    name        TEXT        NOT NULL,
    created_by  UUID        NOT NULL REFERENCES auth.users(id),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE group_expenses (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id        UUID        NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
    description     TEXT        NOT NULL,
    total_amount    NUMERIC(12, 2) NOT NULL CHECK (total_amount > 0),
    paid_by         UUID        NOT NULL REFERENCES auth.users(id),
    date            DATE        NOT NULL,
    split_type      TEXT        NOT NULL CHECK (split_type IN ('igual', 'porcentaje', 'personalizado')), -- Nuevo (Pantalla 18 y 20)
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Tabla: group_members (Miembros del grupo)
-- Representa la pertenencia de un usuario a un grupo.
-- Un miembro puede estar activo (aceptó) o pendiente (invitación sin aceptar).
-- No se pueden eliminar ni editar miembros (regla de negocio).
-- Relación: muchos group_members → 1 groups
--           muchos group_members → 1 profiles (usuario miembro)
--           Unicidad: un usuario solo puede aparecer una vez por grupo
CREATE TABLE group_members (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id    UUID        NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
    user_id     UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    status      TEXT        NOT NULL CHECK (status IN ('activo', 'pendiente')) DEFAULT 'pendiente',
    joined_at   TIMESTAMPTZ,                  -- NULL si aún no ha aceptado
    CONSTRAINT unique_member_per_group UNIQUE (group_id, user_id)
);

-- Tabla: group_expenses (Gastos compartidos)
-- Cada gasto registrado dentro de un grupo.
-- Cualquier miembro activo puede registrar un gasto en nombre de otro miembro.
-- Relación: muchos group_expenses → 1 groups
--           muchos group_expenses → 1 profiles (quien pagó)
--           1 group_expense → muchos expense_splits
CREATE TABLE group_expenses (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id        UUID        NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
    description     TEXT        NOT NULL,
    total_amount    NUMERIC(12, 2) NOT NULL CHECK (total_amount > 0),
    paid_by         UUID        NOT NULL REFERENCES auth.users(id),
    date            DATE        NOT NULL,
    split_type      TEXT        NOT NULL CHECK (split_type IN ('igual', 'porcentaje', 'personalizado')),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Tabla: expense_splits (División del gasto)
-- Una fila por participante en cada gasto compartido.
-- Si el participante es quien pagó, amount_owed = 0.
-- Se regenera completamente al editar un gasto.
-- Relación: muchos expense_splits → 1 group_expenses
--           muchos expense_splits → 1 profiles (participante)
CREATE TABLE expense_splits (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    expense_id      UUID        NOT NULL REFERENCES group_expenses(id) ON DELETE CASCADE,
    user_id         UUID        NOT NULL REFERENCES auth.users(id),
    amount_owed     NUMERIC(12, 2) NOT NULL CHECK (amount_owed >= 0),
    percentage      NUMERIC(5, 2),
    CONSTRAINT unique_split_per_expense UNIQUE (expense_id, user_id)
);

-- Tabla: payments (Pagos entre miembros)
-- Registro de pagos realizados fuera de la app (Yape, efectivo, etc.)
-- No tienen CRUD: solo se crean, nunca se editan ni eliminan.
-- El balance siempre se recalcula en tiempo real usando esta tabla.
-- Relación: muchos payments → 1 groups
--           muchos payments → 1 profiles (quien paga)
--           muchos payments → 1 profiles (quien recibe)
CREATE TABLE payments (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id        UUID        NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
    from_user_id    UUID        NOT NULL REFERENCES auth.users(id),
    to_user_id      UUID        NOT NULL REFERENCES auth.users(id),
    amount          NUMERIC(12, 2) NOT NULL CHECK (amount > 0),
    note            TEXT,
    date            DATE        NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT pagos_distintos CHECK (from_user_id <> to_user_id)
);


-- ============================================================
-- ÍNDICES
-- ============================================================

-- Movimientos personales: filtros más comunes
CREATE INDEX idx_movements_user_id     ON movements(user_id);
CREATE INDEX idx_movements_user_date   ON movements(user_id, date DESC);
CREATE INDEX idx_movements_category    ON movements(category_id);

-- Presupuestos: búsqueda por usuario y categoría (validación de solapamiento)
CREATE INDEX idx_budgets_user_id       ON budgets(user_id);
CREATE INDEX idx_budgets_user_category ON budgets(user_id, category_id);

-- Grupos: miembros y gastos
CREATE INDEX idx_group_members_user    ON group_members(user_id);
CREATE INDEX idx_group_members_group   ON group_members(group_id);
CREATE INDEX idx_group_expenses_group  ON group_expenses(group_id);
CREATE INDEX idx_expense_splits_expense ON expense_splits(expense_id);
CREATE INDEX idx_expense_splits_user   ON expense_splits(user_id);

-- Pagos: cálculo de balances
CREATE INDEX idx_payments_group        ON payments(group_id);
CREATE INDEX idx_payments_from_user    ON payments(from_user_id);
CREATE INDEX idx_payments_to_user      ON payments(to_user_id);


-- ============================================================
-- TRIGGER: updated_at automático
-- ============================================================

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_movements_updated_at
    BEFORE UPDATE ON movements
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_budgets_updated_at
    BEFORE UPDATE ON budgets
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();


-- ============================================================
-- SEED: Categorías predefinidas
-- (Fijas. El usuario nunca las modifica.)
-- ============================================================

INSERT INTO categories (id, name, type, icon) VALUES
    -- Ingresos
    (gen_random_uuid(), 'Salario',          'income',  'wallet'),
    (gen_random_uuid(), 'Inversiones',      'income',  'trending_up'),
    (gen_random_uuid(), 'Reembolso',        'income',  'undo'),
    (gen_random_uuid(), 'Regalo',           'income',  'gift'),
    (gen_random_uuid(), 'Otros',            'income',  'more_horiz'),
    -- Gastos
    (gen_random_uuid(), 'Comida',           'expense', 'fork_knife'),
    (gen_random_uuid(), 'Transporte',       'expense', 'directions_bus'),
    (gen_random_uuid(), 'Entretenimiento',  'expense', 'movie'),
    (gen_random_uuid(), 'Salud',            'expense', 'health_cross'),
    (gen_random_uuid(), 'Compras',          'expense', 'shopping_bag'),
    (gen_random_uuid(), 'Otros',            'expense', 'more_horiz');
