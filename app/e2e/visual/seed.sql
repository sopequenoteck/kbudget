--
-- PostgreSQL database dump
--

\restrict iVEnAqEzep6J6bJd41ihEHRnfhfO7ZYjO7uzyres4JdUuWToDRcgh58CGdZ6pZl

-- Dumped from database version 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)
-- Dumped by pg_dump version 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: unaccent; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS unaccent WITH SCHEMA public;


--
-- Name: EXTENSION unaccent; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION unaccent IS 'text search dictionary that removes accents';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    nom character varying(50) NOT NULL,
    type character varying(20) NOT NULL,
    solde_initial numeric(19,2) DEFAULT 0.00 NOT NULL,
    icone character varying(10) NOT NULL,
    couleur character varying(7) NOT NULL,
    is_default boolean DEFAULT false NOT NULL,
    actif boolean DEFAULT true NOT NULL,
    updated_at timestamp without time zone,
    user_id uuid NOT NULL,
    currency character varying(3) DEFAULT 'EUR'::character varying NOT NULL,
    bank_code character varying(20) DEFAULT 'OTHER'::character varying NOT NULL,
    bank_custom_name character varying(100),
    bank_custom_logo text,
    statement_profile_key character varying(64),
    statement_account_suffix character varying(4)
);


--
-- Name: budget_snapshots; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.budget_snapshots (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    montant_budget numeric(12,2) NOT NULL,
    currency character varying(3) NOT NULL,
    taux_change numeric(20,6),
    montant_depense numeric(12,2) NOT NULL,
    mois character varying(7) NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    category_id uuid NOT NULL,
    user_id uuid NOT NULL
);


--
-- Name: budgets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.budgets (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    montant numeric(12,2) NOT NULL,
    currency character varying(3) DEFAULT 'EUR'::character varying NOT NULL,
    frequence character varying(20) NOT NULL,
    seuil_notification integer DEFAULT 80 NOT NULL,
    actif boolean DEFAULT true NOT NULL,
    updated_at timestamp without time zone,
    category_id uuid NOT NULL,
    user_id uuid NOT NULL
);


--
-- Name: categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.categories (
    id uuid NOT NULL,
    nom character varying(30) NOT NULL,
    icone character varying(50) NOT NULL,
    couleur character varying(7) NOT NULL,
    updated_at timestamp without time zone,
    user_id uuid NOT NULL,
    is_system boolean DEFAULT false NOT NULL,
    system_key character varying(20)
);


--
-- Name: category_rules; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.category_rules (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    pattern character varying(200) NOT NULL,
    category_id uuid NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    origin character varying(10) DEFAULT 'MANUAL'::character varying NOT NULL
);


--
-- Name: debts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.debts (
    id uuid NOT NULL,
    personne character varying(255) NOT NULL,
    montant numeric(19,2) NOT NULL,
    sens character varying(50) NOT NULL,
    date date NOT NULL,
    rembourse boolean DEFAULT false NOT NULL,
    user_id uuid NOT NULL,
    updated_at timestamp without time zone,
    category_id uuid,
    currency character varying(3) DEFAULT 'EUR'::character varying NOT NULL,
    due_date date,
    account_id uuid,
    include_in_balance boolean DEFAULT false NOT NULL,
    reminder_date date,
    reminder_time time without time zone
);


--
-- Name: exchange_rates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.exchange_rates (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    base_currency character varying(3) NOT NULL,
    target_currency character varying(3) NOT NULL,
    rate numeric(20,6) NOT NULL,
    updated_at timestamp without time zone DEFAULT now(),
    CONSTRAINT exchange_rates_check CHECK (((base_currency)::text <> (target_currency)::text)),
    CONSTRAINT exchange_rates_rate_check CHECK ((rate > (0)::numeric))
);


--
-- Name: flyway_schema_history; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.flyway_schema_history (
    installed_rank integer NOT NULL,
    version character varying(50),
    description character varying(200) NOT NULL,
    type character varying(20) NOT NULL,
    script character varying(1000) NOT NULL,
    checksum integer,
    installed_by character varying(100) NOT NULL,
    installed_on timestamp without time zone DEFAULT now() NOT NULL,
    execution_time integer NOT NULL,
    success boolean NOT NULL
);


--
-- Name: import_draft_lines; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.import_draft_lines (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    draft_id uuid NOT NULL,
    line_number integer NOT NULL,
    raw_label character varying(500) NOT NULL,
    clean_label character varying(500) NOT NULL,
    amount numeric(19,2) NOT NULL,
    date date NOT NULL,
    transaction_type character varying(20) NOT NULL,
    status character varying(20) DEFAULT 'READY'::character varying NOT NULL,
    status_message character varying(500),
    category_id uuid,
    duplicate_transaction_id uuid,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    skip_reason character varying(30),
    category_source character varying(20),
    purchase_date date,
    matched_transaction_id uuid,
    match_candidate_ids text,
    subscription_id uuid,
    read_error character varying(30),
    read_error_value character varying(500)
);


--
-- Name: import_drafts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.import_drafts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    account_id uuid NOT NULL,
    status character varying(20) DEFAULT 'PENDING'::character varying NOT NULL,
    file_name character varying(255),
    total_lines integer DEFAULT 0 NOT NULL,
    ready_count integer DEFAULT 0 NOT NULL,
    review_count integer DEFAULT 0 NOT NULL,
    duplicate_count integer DEFAULT 0 NOT NULL,
    skipped_count integer DEFAULT 0 NOT NULL,
    profile_id uuid,
    profile_source character varying(20),
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone,
    expires_at timestamp without time zone NOT NULL,
    already_imported_count integer DEFAULT 0 NOT NULL,
    statement_profile_key character varying(64),
    statement_account_suffix character varying(4),
    statement_balance numeric(19,2),
    statement_balance_date date,
    matched_count integer DEFAULT 0 NOT NULL
);


--
-- Name: import_history; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.import_history (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    account_id uuid NOT NULL,
    transaction_count integer NOT NULL,
    file_name character varying(255),
    imported_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: import_profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.import_profiles (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    name character varying(100) NOT NULL,
    separator character varying(5) DEFAULT ','::character varying NOT NULL,
    date_format character varying(20) DEFAULT 'dd/MM/yyyy'::character varying NOT NULL,
    date_column character varying(50) NOT NULL,
    amount_column character varying(50),
    debit_column character varying(50),
    credit_column character varying(50),
    label_column character varying(50) NOT NULL,
    encoding character varying(20) DEFAULT 'UTF-8'::character varying NOT NULL,
    decimal_separator character varying(1) DEFAULT '.'::character varying NOT NULL,
    skip_header_lines integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    cleanup_patterns jsonb
);


--
-- Name: invitation; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.invitation (
    id bigint NOT NULL,
    token uuid NOT NULL,
    email character varying(255) NOT NULL,
    invited_by_user_id uuid NOT NULL,
    expires_at timestamp without time zone NOT NULL,
    used_at timestamp without time zone,
    revoked_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: invitation_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.invitation_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: invitation_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.invitation_id_seq OWNED BY public.invitation.id;


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notifications (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    type character varying(50) NOT NULL,
    title character varying(255) NOT NULL,
    message text NOT NULL,
    entity_type character varying(50),
    entity_id uuid,
    read boolean DEFAULT false NOT NULL,
    read_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    params jsonb,
    CONSTRAINT chk_entity_ref CHECK ((((entity_type IS NULL) AND (entity_id IS NULL)) OR ((entity_type IS NOT NULL) AND (entity_id IS NOT NULL))))
);


--
-- Name: refresh_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.refresh_tokens (
    id uuid NOT NULL,
    token character varying(64) NOT NULL,
    status character varying(20) DEFAULT 'ACTIVE'::character varying NOT NULL,
    user_id uuid NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    expires_at timestamp without time zone NOT NULL
);


--
-- Name: subscriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.subscriptions (
    id uuid NOT NULL,
    nom character varying(255) NOT NULL,
    montant numeric(19,2) NOT NULL,
    frequence character varying(50) NOT NULL,
    date_debut date NOT NULL,
    actif boolean DEFAULT true NOT NULL,
    user_id uuid NOT NULL,
    updated_at timestamp without time zone,
    category_id uuid,
    account_id uuid,
    currency character varying(3) DEFAULT 'EUR'::character varying NOT NULL,
    statement_merchant_key character varying(500)
);


--
-- Name: transactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.transactions (
    id uuid NOT NULL,
    montant numeric(19,2) NOT NULL,
    libelle character varying(255) NOT NULL,
    type character varying(50) NOT NULL,
    date date NOT NULL,
    note character varying(255),
    user_id uuid NOT NULL,
    updated_at timestamp without time zone,
    category_id uuid,
    account_id uuid NOT NULL,
    transfer_id uuid,
    debt_id uuid,
    is_recurring boolean DEFAULT false NOT NULL,
    frequency character varying(20),
    next_occurrence date,
    recurring_active boolean DEFAULT true NOT NULL,
    subscription_id uuid,
    import_fingerprint character varying(64)
);


--
-- Name: user_preferences; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_preferences (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    enabled_features character varying(255) DEFAULT 'SUBSCRIPTIONS,DEBTS,SHOP'::character varying NOT NULL,
    nav_order character varying(255) DEFAULT 'SUBSCRIPTIONS,DEBTS,SHOP'::character varying NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    currencies character varying(100) DEFAULT 'EUR'::character varying NOT NULL,
    enabled_notification_types character varying(255),
    timezone character varying(50) DEFAULT 'Europe/Paris'::character varying,
    text_scale character varying(20) DEFAULT 'MEDIUM'::character varying,
    language character varying(16)
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id uuid NOT NULL,
    email character varying(255) NOT NULL,
    password character varying(255) NOT NULL,
    name character varying(255),
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    disabled_at timestamp without time zone,
    is_admin boolean DEFAULT false NOT NULL,
    password_reset_required boolean DEFAULT false NOT NULL,
    avatar_path character varying(512)
);


--
-- Name: COLUMN users.avatar_path; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.users.avatar_path IS 'Chemin relatif vers l''avatar redimensionné (256x256 JPEG) stocké sur disque local. NULL si aucun avatar uploadé.';


--
-- Name: invitation id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invitation ALTER COLUMN id SET DEFAULT nextval('public.invitation_id_seq'::regclass);


--
-- Data for Name: accounts; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.accounts (id, nom, type, solde_initial, icone, couleur, is_default, actif, updated_at, user_id, currency, bank_code, bank_custom_name, bank_custom_logo, statement_profile_key, statement_account_suffix) FROM stdin;
3230215a-8fe9-4131-8200-271a7c9aee77	Compte Courant	COURANT	2450.00	🏦	#3b82f6	t	t	\N	1c27c80e-d0f4-4c7f-9dca-e1a64b378205	EUR	BNP	\N	\N	\N	\N
e94cfac4-5286-4504-ace5-bdc0aa95b5e5	Compte Principal	COURANT	0.00	🏦	#3b82f6	f	t	\N	1c27c80e-d0f4-4c7f-9dca-e1a64b378205	EUR	OTHER	\N	\N	\N	\N
206d8272-0ca4-46b3-be5c-2c1da73bd704	Compte CFA	COURANT	850000.00	🌍	#f59e0b	f	t	\N	1c27c80e-d0f4-4c7f-9dca-e1a64b378205	XOF	OTHER	\N	\N	\N	\N
1739ae09-4a3e-4779-8943-e3a6bb4bdbee	Current account	COURANT	2450.00	🏦	#3b82f6	t	t	\N	ad2f63f8-5fb7-4266-bf3c-3972c03e3714	EUR	BNP	\N	\N	\N	\N
5f98f16a-5d5c-4d16-97af-c7f8eaf0ab41	Main account	COURANT	0.00	🏦	#3b82f6	f	t	\N	ad2f63f8-5fb7-4266-bf3c-3972c03e3714	EUR	OTHER	\N	\N	\N	\N
52b510ad-bade-4137-8c1a-fcabfe7980cc	CFA account	COURANT	850000.00	🌍	#f59e0b	f	t	\N	ad2f63f8-5fb7-4266-bf3c-3972c03e3714	XOF	OTHER	\N	\N	\N	\N
082bef8a-76b8-4aac-aa0f-a4e6bd5c0a67	Compte Principal	COURANT	1200.00	🏦	#3b82f6	t	t	\N	4574530e-bf91-47af-a17f-1926168199fe	EUR	OTHER	\N	\N	\N	\N
e59917e7-e1d7-4eb2-8d91-57b9fb2812ac	Compte Principal	COURANT	1200.00	🏦	#3b82f6	t	t	\N	ef82fe3c-c290-4056-b04c-7560acee05ed	EUR	OTHER	\N	\N	\N	\N
\.


--
-- Data for Name: budget_snapshots; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.budget_snapshots (id, montant_budget, currency, taux_change, montant_depense, mois, created_at, category_id, user_id) FROM stdin;
\.


--
-- Data for Name: budgets; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.budgets (id, montant, currency, frequence, seuil_notification, actif, updated_at, category_id, user_id) FROM stdin;
66ba1aca-bcbc-4e3f-9b70-aa4e4f939cf0	400.00	EUR	MENSUEL	80	t	\N	8e21fade-65a0-4e5b-81fc-de5a81db9199	1c27c80e-d0f4-4c7f-9dca-e1a64b378205
78670a8f-7fce-46cd-a6a7-106f0627bef7	150.00	EUR	MENSUEL	75	t	\N	288582f7-5be1-47cf-aaa0-17c4c453461b	1c27c80e-d0f4-4c7f-9dca-e1a64b378205
24994b85-1262-43fa-879d-41bf831b9669	100.00	EUR	MENSUEL	90	t	\N	49d09033-9704-4693-991b-e59c1cff37ea	1c27c80e-d0f4-4c7f-9dca-e1a64b378205
76cdd6e5-3fcb-49b3-a8a7-e1be513280d8	200.00	EUR	MENSUEL	80	t	\N	f1ea2824-1b5a-4287-b498-d17c3e7ece24	1c27c80e-d0f4-4c7f-9dca-e1a64b378205
c99b1e11-3224-4f54-ab91-4ee984928a31	120000.00	XOF	MENSUEL	80	t	\N	79149cec-cce1-4729-86ce-556d26678b9e	1c27c80e-d0f4-4c7f-9dca-e1a64b378205
e73a8354-c86b-459c-8c40-668b9de376f0	400.00	EUR	MENSUEL	80	t	\N	14655205-689b-4285-9b04-acfac5e7c169	ad2f63f8-5fb7-4266-bf3c-3972c03e3714
486a0ccf-f8ca-490a-adf4-bcd3845a149f	150.00	EUR	MENSUEL	75	t	\N	f17aa566-36a8-4255-b2ed-4bb5f20a4b3e	ad2f63f8-5fb7-4266-bf3c-3972c03e3714
f695e907-c1c9-41f3-9aad-d3a1416e3a60	100.00	EUR	MENSUEL	90	t	\N	f9123ad2-9fcb-4011-bfe0-c2e6626683fa	ad2f63f8-5fb7-4266-bf3c-3972c03e3714
e2e41f86-7adf-4259-929e-b4d0e1a26e4c	200.00	EUR	MENSUEL	80	t	\N	7dc4e56f-56d4-4c82-af6d-8a76a5771c1e	ad2f63f8-5fb7-4266-bf3c-3972c03e3714
7ac9cec4-630a-45a3-af16-252fc736a5b6	120000.00	XOF	MENSUEL	80	t	\N	24418c02-db83-43f1-bc6f-c500c30cf081	ad2f63f8-5fb7-4266-bf3c-3972c03e3714
\.


--
-- Data for Name: categories; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.categories (id, nom, icone, couleur, updated_at, user_id, is_system, system_key) FROM stdin;
71a79df3-f3b6-4016-b84a-045523c87cfd	Abonnement	🔄	#6366f1	\N	1c27c80e-d0f4-4c7f-9dca-e1a64b378205	t	SUBSCRIPTION
94f92ccd-8a1a-4ce5-af61-6c0b927b182e	Dette	💰	#ef4444	\N	1c27c80e-d0f4-4c7f-9dca-e1a64b378205	t	DEBT
1f08cd1e-6f69-49c3-b162-9e77b8e2a533	Virement	🔄	#8b5cf6	\N	1c27c80e-d0f4-4c7f-9dca-e1a64b378205	t	TRANSFER
8e21fade-65a0-4e5b-81fc-de5a81db9199	Alimentation	🛒	#22c55e	\N	1c27c80e-d0f4-4c7f-9dca-e1a64b378205	f	\N
288582f7-5be1-47cf-aaa0-17c4c453461b	Transport	🚗	#3b82f6	\N	1c27c80e-d0f4-4c7f-9dca-e1a64b378205	f	\N
49d09033-9704-4693-991b-e59c1cff37ea	Loisirs	🎮	#a855f7	\N	1c27c80e-d0f4-4c7f-9dca-e1a64b378205	f	\N
08be50dc-ea9e-4716-83e5-4742c5089ada	Sante	🏥	#ef4444	\N	1c27c80e-d0f4-4c7f-9dca-e1a64b378205	f	\N
82faa757-28f9-4fd7-9854-5683407da627	Logement	🏠	#f97316	\N	1c27c80e-d0f4-4c7f-9dca-e1a64b378205	f	\N
5bc0341d-312f-4db9-9a75-5e3c99485d60	Salaire	💼	#10b981	\N	1c27c80e-d0f4-4c7f-9dca-e1a64b378205	f	\N
b786ff41-9735-4f66-a9d4-b8d8e26c02e2	Freelance	💻	#6366f1	\N	1c27c80e-d0f4-4c7f-9dca-e1a64b378205	f	\N
79149cec-cce1-4729-86ce-556d26678b9e	Courses	🧺	#14b8a6	\N	1c27c80e-d0f4-4c7f-9dca-e1a64b378205	f	\N
f1ea2824-1b5a-4287-b498-d17c3e7ece24	Restaurant	🍽️	#f59e0b	\N	1c27c80e-d0f4-4c7f-9dca-e1a64b378205	f	\N
85c8b18b-577f-46af-a6d6-de115f2c2b74	Subscription	🔄	#6366f1	\N	ad2f63f8-5fb7-4266-bf3c-3972c03e3714	t	SUBSCRIPTION
9deda646-a1e4-4b53-8d4d-0acdf489e5ff	Debt	💰	#ef4444	\N	ad2f63f8-5fb7-4266-bf3c-3972c03e3714	t	DEBT
39f7d8c5-fb4b-43a5-a8d0-e82197605f24	Transfer	🔄	#8b5cf6	\N	ad2f63f8-5fb7-4266-bf3c-3972c03e3714	t	TRANSFER
14655205-689b-4285-9b04-acfac5e7c169	Food	🛒	#22c55e	\N	ad2f63f8-5fb7-4266-bf3c-3972c03e3714	f	\N
f17aa566-36a8-4255-b2ed-4bb5f20a4b3e	Transport	🚗	#3b82f6	\N	ad2f63f8-5fb7-4266-bf3c-3972c03e3714	f	\N
f9123ad2-9fcb-4011-bfe0-c2e6626683fa	Leisure	🎮	#a855f7	\N	ad2f63f8-5fb7-4266-bf3c-3972c03e3714	f	\N
f5fb2807-184b-42af-9f9b-b41e1b21b8ce	Health	🏥	#ef4444	\N	ad2f63f8-5fb7-4266-bf3c-3972c03e3714	f	\N
12183a1c-9d4b-4335-aa84-39763cc0e18a	Housing	🏠	#f97316	\N	ad2f63f8-5fb7-4266-bf3c-3972c03e3714	f	\N
dea77827-e7b6-421a-bc94-0b2506bffc80	Salary	💼	#10b981	\N	ad2f63f8-5fb7-4266-bf3c-3972c03e3714	f	\N
ec7a868c-874f-41a0-bb77-45f2f9828775	Freelance	💻	#6366f1	\N	ad2f63f8-5fb7-4266-bf3c-3972c03e3714	f	\N
24418c02-db83-43f1-bc6f-c500c30cf081	Groceries	🧺	#14b8a6	\N	ad2f63f8-5fb7-4266-bf3c-3972c03e3714	f	\N
7dc4e56f-56d4-4c82-af6d-8a76a5771c1e	Restaurant	🍽️	#f59e0b	\N	ad2f63f8-5fb7-4266-bf3c-3972c03e3714	f	\N
0902580f-2b97-4f6b-9713-55ec113b319a	Abonnement	🔄	#6366f1	\N	4574530e-bf91-47af-a17f-1926168199fe	t	SUBSCRIPTION
370dddf7-d81b-41d5-a451-c902ac9074f9	Dette	💰	#ef4444	\N	4574530e-bf91-47af-a17f-1926168199fe	t	DEBT
ad30d59f-6975-4ff1-9c3d-4c0897032ee2	Virement	🔄	#8b5cf6	\N	4574530e-bf91-47af-a17f-1926168199fe	t	TRANSFER
51c0d8f9-22cd-4922-af1b-f8941b18eb17	Courses	🧺	#14b8a6	\N	4574530e-bf91-47af-a17f-1926168199fe	f	\N
472f92c5-6b44-4ce9-b909-067e316692f7	Salaire	💼	#10b981	\N	4574530e-bf91-47af-a17f-1926168199fe	f	\N
e4d0f0ce-4641-46a0-b8de-f0b59718e4aa	Abonnement	🔄	#6366f1	\N	ef82fe3c-c290-4056-b04c-7560acee05ed	t	SUBSCRIPTION
379f8057-c397-4088-a2a9-728bf5213ef2	Dette	💰	#ef4444	\N	ef82fe3c-c290-4056-b04c-7560acee05ed	t	DEBT
0247b29b-73d2-476a-9139-9b0faac1c29e	Virement	🔄	#8b5cf6	\N	ef82fe3c-c290-4056-b04c-7560acee05ed	t	TRANSFER
9eb46ec9-6761-4227-a5a1-bfa8383e76dc	Courses	🧺	#14b8a6	\N	ef82fe3c-c290-4056-b04c-7560acee05ed	f	\N
ee8fb6a5-2532-4fc0-b236-597b931a17b1	Salaire	💼	#10b981	\N	ef82fe3c-c290-4056-b04c-7560acee05ed	f	\N
\.


--
-- Data for Name: category_rules; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.category_rules (id, user_id, pattern, category_id, created_at, origin) FROM stdin;
\.


--
-- Data for Name: debts; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.debts (id, personne, montant, sens, date, rembourse, user_id, updated_at, category_id, currency, due_date, account_id, include_in_balance, reminder_date, reminder_time) FROM stdin;
6111429a-6d3a-4dcb-9403-157e639684c0	Kofi	150000.00	PRET	2026-09-05	f	1c27c80e-d0f4-4c7f-9dca-e1a64b378205	\N	94f92ccd-8a1a-4ce5-af61-6c0b927b182e	XOF	2026-11-16	206d8272-0ca4-46b3-be5c-2c1da73bd704	f	\N	\N
bd609519-5f83-4d19-ae00-647e3f4b5e42	Marie	200.00	EMPRUNT	2026-09-19	f	1c27c80e-d0f4-4c7f-9dca-e1a64b378205	\N	94f92ccd-8a1a-4ce5-af61-6c0b927b182e	EUR	2026-10-22	3230215a-8fe9-4131-8200-271a7c9aee77	f	\N	\N
daa01338-8f6d-4c07-969a-f6ed82ff0c65	Papa	500.00	EMPRUNT	2026-07-31	t	1c27c80e-d0f4-4c7f-9dca-e1a64b378205	\N	94f92ccd-8a1a-4ce5-af61-6c0b927b182e	EUR	2026-09-28	3230215a-8fe9-4131-8200-271a7c9aee77	f	\N	\N
e086d638-0318-4bf5-8113-258283df4a0e	Kofi	150000.00	PRET	2026-09-05	f	ad2f63f8-5fb7-4266-bf3c-3972c03e3714	\N	9deda646-a1e4-4b53-8d4d-0acdf489e5ff	XOF	2026-11-16	52b510ad-bade-4137-8c1a-fcabfe7980cc	f	\N	\N
cb7d09dc-3c97-4a52-9613-7481ffdaf12f	Marie	200.00	EMPRUNT	2026-09-19	f	ad2f63f8-5fb7-4266-bf3c-3972c03e3714	\N	9deda646-a1e4-4b53-8d4d-0acdf489e5ff	EUR	2026-10-22	1739ae09-4a3e-4779-8943-e3a6bb4bdbee	f	\N	\N
2555bb48-dfa1-4400-9300-41181368f667	Dad	500.00	EMPRUNT	2026-07-31	t	ad2f63f8-5fb7-4266-bf3c-3972c03e3714	\N	9deda646-a1e4-4b53-8d4d-0acdf489e5ff	EUR	2026-09-28	1739ae09-4a3e-4779-8943-e3a6bb4bdbee	f	\N	\N
\.


--
-- Data for Name: exchange_rates; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.exchange_rates (id, user_id, base_currency, target_currency, rate, updated_at) FROM stdin;
df720cb0-4321-4584-b38e-a6e965ee9a07	1c27c80e-d0f4-4c7f-9dca-e1a64b378205	EUR	XOF	655.957000	2026-10-25 23:26:01.32167
a2da01f1-c3d1-43b0-ac07-39cbd80eb16f	ad2f63f8-5fb7-4266-bf3c-3972c03e3714	EUR	XOF	655.957000	2026-10-25 23:26:01.32167
\.


--
-- Data for Name: flyway_schema_history; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.flyway_schema_history (installed_rank, version, description, type, script, checksum, installed_by, installed_on, execution_time, success) FROM stdin;
1	1	init schema	SQL	V1__init_schema.sql	1709730213	budget_u	2026-10-25 23:26:00.447588	30	t
2	2	add updated at	SQL	V2__add_updated_at.sql	-560756230	budget_u	2026-10-25 23:26:00.513324	8	t
3	3	add categories	SQL	V3__add_categories.sql	604202237	budget_u	2026-10-25 23:26:00.540538	25	t
4	4	rename debt type values	SQL	V4__rename_debt_type_values.sql	1321468234	budget_u	2026-10-25 23:26:00.581063	7	t
5	5	add is system and seed	SQL	V5__add_is_system_and_seed.sql	-1181515324	budget_u	2026-10-25 23:26:00.606514	16	t
6	6	add refresh tokens	SQL	V6__add_refresh_tokens.sql	-1888845611	budget_u	2026-10-25 23:26:00.641818	18	t
7	7	add accounts	SQL	V7__add_accounts.sql	740509660	budget_u	2026-10-25 23:26:00.674147	42	t
8	8	add currency support	SQL	V8__add_currency_support.sql	-1711027168	budget_u	2026-10-25 23:26:00.742192	5	t
9	9	add user preferences	SQL	V9__add_user_preferences.sql	-1220893141	budget_u	2026-10-25 23:26:00.760381	13	t
10	10	add products	SQL	V10__add_products.sql	1162354479	budget_u	2026-10-25 23:26:00.791604	13	t
11	11	add shop support	SQL	V11__add_shop_support.sql	-624958690	budget_u	2026-10-25 23:26:00.819678	10	t
12	12	alter product image url to text	SQL	V12__alter_product_image_url_to_text.sql	-770615115	budget_u	2026-10-25 23:26:00.841304	2	t
13	13	add currencies and exchange rates	SQL	V13__add_currencies_and_exchange_rates.sql	790573539	budget_u	2026-10-25 23:26:00.850576	17	t
14	14	remove user default currency	SQL	V14__remove_user_default_currency.sql	1187222596	budget_u	2026-10-25 23:26:00.883147	5	t
15	15	add notifications	SQL	V15__add_notifications.sql	1851627767	budget_u	2026-10-25 23:26:00.901672	18	t
16	16	add debt due date	SQL	V16__add_debt_due_date.sql	-992809265	budget_u	2026-10-25 23:26:00.930171	2	t
17	17	add budgets	SQL	V17__add_budgets.sql	-1411502046	budget_u	2026-10-25 23:26:00.938218	15	t
18	18	add debt enhancements	SQL	V18__add_debt_enhancements.sql	2053829164	budget_u	2026-10-25 23:26:00.964496	13	t
19	19	add bank to accounts	SQL	V19__add_bank_to_accounts.sql	-59573245	budget_u	2026-10-25 23:26:00.985996	4	t
20	20	add recurring to transactions	SQL	V20__add_recurring_to_transactions.sql	1876582346	budget_u	2026-10-25 23:26:01.002341	6	t
21	21	add text scale	SQL	V21__add_text_scale.sql	496264350	budget_u	2026-10-25 23:26:01.015408	5	t
22	22	csv import	SQL	V22__csv_import.sql	-214316874	budget_u	2026-10-25 23:26:01.027504	19	t
23	23	add updated at import drafts	SQL	V23__add_updated_at_import_drafts.sql	-323240698	budget_u	2026-10-25 23:26:01.05443	6	t
24	24	seed april 2026	SQL	V24__seed_april_2026.sql	2145709614	budget_u	2026-10-25 23:26:01.069322	3	t
25	26	drop shop	SQL	V26__drop_shop.sql	832269170	budget_u	2026-10-25 23:26:01.07853	8	t
26	27	enable unaccent extension	SQL	V27__enable_unaccent_extension.sql	-240536801	budget_u	2026-10-25 23:26:01.11961	8	t
27	28	add invitations	SQL	V28__add_invitations.sql	-786222757	budget_u	2026-10-25 23:26:01.135182	10	t
28	29	add user disabled at	SQL	V29__add_user_disabled_at.sql	-1298128553	budget_u	2026-10-25 23:26:01.151294	2	t
29	30	add user is admin	SQL	V30__add_user_is_admin.sql	892042978	budget_u	2026-10-25 23:26:01.15855	1	t
30	31	add user password reset required	SQL	V31__add_user_password_reset_required.sql	617604101	budget_u	2026-10-25 23:26:01.166521	2	t
31	32	add user avatar path	SQL	V32__add_user_avatar_path.sql	304406317	budget_u	2026-10-25 23:26:01.174004	3	t
32	33	patch budgets user fk cascade	SQL	V33__patch_budgets_user_fk_cascade.sql	1817215719	budget_u	2026-10-25 23:26:01.184159	5	t
33	34	patch budget snapshots user fk cascade	SQL	V34__patch_budget_snapshots_user_fk_cascade.sql	864240997	budget_u	2026-10-25 23:26:01.196075	4	t
34	35	patch refresh tokens user fk cascade	SQL	V35__patch_refresh_tokens_user_fk_cascade.sql	887452790	budget_u	2026-10-25 23:26:01.20505	2	t
35	36	import fingerprint and skip reason	SQL	V36__import_fingerprint_and_skip_reason.sql	852622509	budget_u	2026-10-25 23:26:01.215045	4	t
36	37	category source and rule origin	SQL	V37__category_source_and_rule_origin.sql	155881838	budget_u	2026-10-25 23:26:01.225565	2	t
37	38	add language preference	SQL	V38__add_language_preference.sql	-1307367956	budget_u	2026-10-25 23:26:01.233776	2	t
38	39	category system key	SQL	V39__category_system_key.sql	1474185562	budget_u	2026-10-25 23:26:01.240807	3	t
39	40	notification params	SQL	V40__notification_params.sql	2126902980	budget_u	2026-10-25 23:26:01.248594	2	t
40	41	statement balance and account recognition	SQL	V41__statement_balance_and_account_recognition.sql	1316593662	budget_u	2026-10-25 23:26:01.257145	4	t
41	42	import reconciliation	SQL	V42__import_reconciliation.sql	-433203813	budget_u	2026-10-25 23:26:01.267301	8	t
42	43	import line read error	SQL	V43__import_line_read_error.sql	233623628	budget_u	2026-10-25 23:26:01.284796	2	t
43	44	import profile cleanup patterns	SQL	V44__import_profile_cleanup_patterns.sql	853051454	budget_u	2026-10-25 23:26:01.293063	4	t
44	\N	dev seed	SQL	R__dev_seed.sql	1713945032	budget_u	2026-10-25 23:26:01.301902	66	t
\.


--
-- Data for Name: import_draft_lines; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.import_draft_lines (id, draft_id, line_number, raw_label, clean_label, amount, date, transaction_type, status, status_message, category_id, duplicate_transaction_id, created_at, updated_at, skip_reason, category_source, purchase_date, matched_transaction_id, match_candidate_ids, subscription_id, read_error, read_error_value) FROM stdin;
\.


--
-- Data for Name: import_drafts; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.import_drafts (id, user_id, account_id, status, file_name, total_lines, ready_count, review_count, duplicate_count, skipped_count, profile_id, profile_source, created_at, updated_at, expires_at, already_imported_count, statement_profile_key, statement_account_suffix, statement_balance, statement_balance_date, matched_count) FROM stdin;
\.


--
-- Data for Name: import_history; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.import_history (id, user_id, account_id, transaction_count, file_name, imported_at) FROM stdin;
\.


--
-- Data for Name: import_profiles; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.import_profiles (id, user_id, name, separator, date_format, date_column, amount_column, debit_column, credit_column, label_column, encoding, decimal_separator, skip_header_lines, created_at, updated_at, cleanup_patterns) FROM stdin;
\.


--
-- Data for Name: invitation; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.invitation (id, token, email, invited_by_user_id, expires_at, used_at, revoked_at, created_at) FROM stdin;
\.


--
-- Data for Name: notifications; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.notifications (id, user_id, type, title, message, entity_type, entity_id, read, read_at, created_at, params) FROM stdin;
\.


--
-- Data for Name: subscriptions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.subscriptions (id, nom, montant, frequence, date_debut, actif, user_id, updated_at, category_id, account_id, currency, statement_merchant_key) FROM stdin;
3a91354a-af55-4678-8535-887b2a91f6e1	Netflix	13.49	MENSUEL	2025-12-20	t	1c27c80e-d0f4-4c7f-9dca-e1a64b378205	\N	71a79df3-f3b6-4016-b84a-045523c87cfd	3230215a-8fe9-4131-8200-271a7c9aee77	EUR	\N
a17edd2b-afc1-4b89-82c0-5dc597332ee4	Spotify	10.99	MENSUEL	2025-08-05	t	1c27c80e-d0f4-4c7f-9dca-e1a64b378205	\N	71a79df3-f3b6-4016-b84a-045523c87cfd	3230215a-8fe9-4131-8200-271a7c9aee77	EUR	\N
e00f2be0-2a7f-4068-9649-15507ae6a211	Canal+	25.99	MENSUEL	2026-03-22	t	1c27c80e-d0f4-4c7f-9dca-e1a64b378205	\N	71a79df3-f3b6-4016-b84a-045523c87cfd	206d8272-0ca4-46b3-be5c-2c1da73bd704	XOF	\N
f0e1cdfc-58e4-442e-87fe-df949f61e870	Orange Fibre	29.99	MENSUEL	2025-09-28	t	1c27c80e-d0f4-4c7f-9dca-e1a64b378205	\N	71a79df3-f3b6-4016-b84a-045523c87cfd	3230215a-8fe9-4131-8200-271a7c9aee77	EUR	\N
9c360bf3-06a8-4483-ae0c-529dcd58211d	Netflix	13.49	MENSUEL	2025-12-20	t	ad2f63f8-5fb7-4266-bf3c-3972c03e3714	\N	85c8b18b-577f-46af-a6d6-de115f2c2b74	1739ae09-4a3e-4779-8943-e3a6bb4bdbee	EUR	\N
9dd3f889-d8aa-4fa8-aced-3085a5480ac4	Spotify	10.99	MENSUEL	2025-08-05	t	ad2f63f8-5fb7-4266-bf3c-3972c03e3714	\N	85c8b18b-577f-46af-a6d6-de115f2c2b74	1739ae09-4a3e-4779-8943-e3a6bb4bdbee	EUR	\N
4f5498d5-0766-486b-be72-6dd9b9c6b777	Canal+	25.99	MENSUEL	2026-03-22	t	ad2f63f8-5fb7-4266-bf3c-3972c03e3714	\N	85c8b18b-577f-46af-a6d6-de115f2c2b74	52b510ad-bade-4137-8c1a-fcabfe7980cc	XOF	\N
2d9d75ec-3103-4e6d-9084-659ae8220f8b	Orange Fibre	29.99	MENSUEL	2025-09-28	t	ad2f63f8-5fb7-4266-bf3c-3972c03e3714	\N	85c8b18b-577f-46af-a6d6-de115f2c2b74	1739ae09-4a3e-4779-8943-e3a6bb4bdbee	EUR	\N
\.


--
-- Data for Name: transactions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.transactions (id, montant, libelle, type, date, note, user_id, updated_at, category_id, account_id, transfer_id, debt_id, is_recurring, frequency, next_occurrence, recurring_active, subscription_id, import_fingerprint) FROM stdin;
73ab9b53-9007-4126-aeee-59cd5867402a	2800.00	Salaire Mars	RECETTE	2026-09-19	\N	1c27c80e-d0f4-4c7f-9dca-e1a64b378205	\N	5bc0341d-312f-4db9-9a75-5e3c99485d60	3230215a-8fe9-4131-8200-271a7c9aee77	\N	\N	f	\N	\N	t	\N	\N
b9c195be-dc22-4277-b5b6-2522cb79901c	450.00	Mission freelance	RECETTE	2026-09-28	Client Dupont	1c27c80e-d0f4-4c7f-9dca-e1a64b378205	\N	b786ff41-9735-4f66-a9d4-b8d8e26c02e2	3230215a-8fe9-4131-8200-271a7c9aee77	\N	\N	f	\N	\N	t	\N	\N
be3c1c87-1bdf-40d4-8a21-12fee0dff64a	750.00	Loyer mars	DEPENSE	2026-09-19	\N	1c27c80e-d0f4-4c7f-9dca-e1a64b378205	\N	82faa757-28f9-4fd7-9854-5683407da627	3230215a-8fe9-4131-8200-271a7c9aee77	\N	\N	f	\N	\N	t	\N	\N
14c0f8c6-2a12-4e6f-aaf1-8f3b38cdd67c	85.50	Carrefour	DEPENSE	2026-09-21	\N	1c27c80e-d0f4-4c7f-9dca-e1a64b378205	\N	8e21fade-65a0-4e5b-81fc-de5a81db9199	3230215a-8fe9-4131-8200-271a7c9aee77	\N	\N	f	\N	\N	t	\N	\N
a479a0b1-4bce-4bf0-bd59-639c349c6681	42.00	Essence	DEPENSE	2026-09-23	\N	1c27c80e-d0f4-4c7f-9dca-e1a64b378205	\N	288582f7-5be1-47cf-aaa0-17c4c453461b	3230215a-8fe9-4131-8200-271a7c9aee77	\N	\N	f	\N	\N	t	\N	\N
9d67ac8d-719c-417c-8215-04f407d4b800	120.00	Medecin + pharmacie	DEPENSE	2026-09-25	\N	1c27c80e-d0f4-4c7f-9dca-e1a64b378205	\N	08be50dc-ea9e-4716-83e5-4742c5089ada	3230215a-8fe9-4131-8200-271a7c9aee77	\N	\N	f	\N	\N	t	\N	\N
a4c40f08-7a16-4760-8937-e38515be9be6	35.90	Lidl	DEPENSE	2026-09-27	\N	1c27c80e-d0f4-4c7f-9dca-e1a64b378205	\N	79149cec-cce1-4729-86ce-556d26678b9e	3230215a-8fe9-4131-8200-271a7c9aee77	\N	\N	f	\N	\N	t	\N	\N
6b962dec-9f89-4b46-a429-6599048cedbb	28.50	Sushi Shop	DEPENSE	2026-09-30	\N	1c27c80e-d0f4-4c7f-9dca-e1a64b378205	\N	f1ea2824-1b5a-4287-b498-d17c3e7ece24	3230215a-8fe9-4131-8200-271a7c9aee77	\N	\N	f	\N	\N	t	\N	\N
f9c57afb-9632-4325-9d06-42143ceccd06	65.00	Cinema + bowling	DEPENSE	2026-10-03	\N	1c27c80e-d0f4-4c7f-9dca-e1a64b378205	\N	49d09033-9704-4693-991b-e59c1cff37ea	3230215a-8fe9-4131-8200-271a7c9aee77	\N	\N	f	\N	\N	t	\N	\N
45d87fa9-372a-4a4a-860f-ebd6b683462f	92.30	Courses semaine	DEPENSE	2026-10-05	\N	1c27c80e-d0f4-4c7f-9dca-e1a64b378205	\N	8e21fade-65a0-4e5b-81fc-de5a81db9199	3230215a-8fe9-4131-8200-271a7c9aee77	\N	\N	f	\N	\N	t	\N	\N
7c15306d-cd73-4cfe-a469-3aad619f5b6a	15.00	Uber	DEPENSE	2026-10-07	\N	1c27c80e-d0f4-4c7f-9dca-e1a64b378205	\N	288582f7-5be1-47cf-aaa0-17c4c453461b	3230215a-8fe9-4131-8200-271a7c9aee77	\N	\N	f	\N	\N	t	\N	\N
742a8a32-d87a-4b9a-9ead-000c1e70f5cd	48.00	Restaurant italien	DEPENSE	2026-10-10	\N	1c27c80e-d0f4-4c7f-9dca-e1a64b378205	\N	f1ea2824-1b5a-4287-b498-d17c3e7ece24	3230215a-8fe9-4131-8200-271a7c9aee77	\N	\N	f	\N	\N	t	\N	\N
1ced23bc-92f5-493e-90d2-da65fb13a167	110.00	Courses Auchan	DEPENSE	2026-10-13	\N	1c27c80e-d0f4-4c7f-9dca-e1a64b378205	\N	8e21fade-65a0-4e5b-81fc-de5a81db9199	3230215a-8fe9-4131-8200-271a7c9aee77	\N	\N	f	\N	\N	t	\N	\N
14b2c394-4dc6-42d3-ac1c-9d1dc68a1834	55.00	Plein essence	DEPENSE	2026-10-16	\N	1c27c80e-d0f4-4c7f-9dca-e1a64b378205	\N	288582f7-5be1-47cf-aaa0-17c4c453461b	3230215a-8fe9-4131-8200-271a7c9aee77	\N	\N	f	\N	\N	t	\N	\N
ca1f6764-aafc-4cec-ba3d-11cbd18fdeea	2800.00	Salaire Fevrier	RECETTE	2026-08-22	\N	1c27c80e-d0f4-4c7f-9dca-e1a64b378205	\N	5bc0341d-312f-4db9-9a75-5e3c99485d60	3230215a-8fe9-4131-8200-271a7c9aee77	\N	\N	f	\N	\N	t	\N	\N
8af7a449-89ee-49f7-8c03-e10a59735bc0	750.00	Loyer fevrier	DEPENSE	2026-08-22	\N	1c27c80e-d0f4-4c7f-9dca-e1a64b378205	\N	82faa757-28f9-4fd7-9854-5683407da627	3230215a-8fe9-4131-8200-271a7c9aee77	\N	\N	f	\N	\N	t	\N	\N
f775baee-c553-44bc-9255-b9172388f818	95.00	Courses Carrefour	DEPENSE	2026-08-25	\N	1c27c80e-d0f4-4c7f-9dca-e1a64b378205	\N	8e21fade-65a0-4e5b-81fc-de5a81db9199	3230215a-8fe9-4131-8200-271a7c9aee77	\N	\N	f	\N	\N	t	\N	\N
555de3fd-600e-4cee-84f1-90f47474a797	38.00	Essence	DEPENSE	2026-08-29	\N	1c27c80e-d0f4-4c7f-9dca-e1a64b378205	\N	288582f7-5be1-47cf-aaa0-17c4c453461b	3230215a-8fe9-4131-8200-271a7c9aee77	\N	\N	f	\N	\N	t	\N	\N
69f0e7fe-4bc4-4e82-982c-536aaa455c89	22.00	Kebab + tacos	DEPENSE	2026-08-31	\N	1c27c80e-d0f4-4c7f-9dca-e1a64b378205	\N	f1ea2824-1b5a-4287-b498-d17c3e7ece24	3230215a-8fe9-4131-8200-271a7c9aee77	\N	\N	f	\N	\N	t	\N	\N
9ba98eba-7874-47f4-a4e8-52048f056b23	180.00	Dentiste	DEPENSE	2026-09-04	\N	1c27c80e-d0f4-4c7f-9dca-e1a64b378205	\N	08be50dc-ea9e-4716-83e5-4742c5089ada	3230215a-8fe9-4131-8200-271a7c9aee77	\N	\N	f	\N	\N	t	\N	\N
3d223fdd-be34-4906-9d05-e3aa9a4104c0	73.50	Courses semaine	DEPENSE	2026-09-08	\N	1c27c80e-d0f4-4c7f-9dca-e1a64b378205	\N	8e21fade-65a0-4e5b-81fc-de5a81db9199	3230215a-8fe9-4131-8200-271a7c9aee77	\N	\N	f	\N	\N	t	\N	\N
a7b0ba38-282f-4077-9735-d194c2a93884	40.00	Jeux video	DEPENSE	2026-09-11	\N	1c27c80e-d0f4-4c7f-9dca-e1a64b378205	\N	49d09033-9704-4693-991b-e59c1cff37ea	3230215a-8fe9-4131-8200-271a7c9aee77	\N	\N	f	\N	\N	t	\N	\N
31edf8be-6f2f-406e-9d50-ed14a5a8afdb	52.00	Plein essence	DEPENSE	2026-09-15	\N	1c27c80e-d0f4-4c7f-9dca-e1a64b378205	\N	288582f7-5be1-47cf-aaa0-17c4c453461b	3230215a-8fe9-4131-8200-271a7c9aee77	\N	\N	f	\N	\N	t	\N	\N
cf00920a-1caa-48bc-8988-e2a177fc5fb8	2800.00	Salaire Avril	RECETTE	2026-10-20	\N	1c27c80e-d0f4-4c7f-9dca-e1a64b378205	\N	5bc0341d-312f-4db9-9a75-5e3c99485d60	3230215a-8fe9-4131-8200-271a7c9aee77	\N	\N	f	\N	\N	t	\N	\N
0146c181-fb70-41bf-adae-10fd30f8b137	750.00	Loyer avril	DEPENSE	2026-10-20	\N	1c27c80e-d0f4-4c7f-9dca-e1a64b378205	\N	82faa757-28f9-4fd7-9854-5683407da627	3230215a-8fe9-4131-8200-271a7c9aee77	\N	\N	f	\N	\N	t	\N	\N
2f649a02-3a60-4f69-a40a-5b55552836e5	29.99	Orange Fibre	DEPENSE	2026-10-20	Prelevement auto	1c27c80e-d0f4-4c7f-9dca-e1a64b378205	\N	71a79df3-f3b6-4016-b84a-045523c87cfd	3230215a-8fe9-4131-8200-271a7c9aee77	\N	\N	f	\N	\N	t	\N	\N
f125c076-ed48-449b-8834-9ce3f94295fb	67.40	Carrefour Market	DEPENSE	2026-10-21	\N	1c27c80e-d0f4-4c7f-9dca-e1a64b378205	\N	8e21fade-65a0-4e5b-81fc-de5a81db9199	3230215a-8fe9-4131-8200-271a7c9aee77	\N	\N	f	\N	\N	t	\N	\N
843a8050-5794-4cdf-ac49-23c62e25f2e2	1.90	Ticket metro	DEPENSE	2026-10-21	\N	1c27c80e-d0f4-4c7f-9dca-e1a64b378205	\N	288582f7-5be1-47cf-aaa0-17c4c453461b	3230215a-8fe9-4131-8200-271a7c9aee77	\N	\N	f	\N	\N	t	\N	\N
b8a3f11c-85a4-4515-bcae-46f35c8fd7cd	12.50	Boulangerie	DEPENSE	2026-10-21	\N	1c27c80e-d0f4-4c7f-9dca-e1a64b378205	\N	8e21fade-65a0-4e5b-81fc-de5a81db9199	3230215a-8fe9-4131-8200-271a7c9aee77	\N	\N	f	\N	\N	t	\N	\N
0cadfd3b-6302-49a4-a3a8-99c837ac4ca8	14.90	Dejeuner kebab	DEPENSE	2026-10-22	\N	1c27c80e-d0f4-4c7f-9dca-e1a64b378205	\N	f1ea2824-1b5a-4287-b498-d17c3e7ece24	3230215a-8fe9-4131-8200-271a7c9aee77	\N	\N	f	\N	\N	t	\N	\N
abc8129e-6864-482f-a538-ec4b4800371c	43.20	Lidl	DEPENSE	2026-10-22	\N	1c27c80e-d0f4-4c7f-9dca-e1a64b378205	\N	79149cec-cce1-4729-86ce-556d26678b9e	3230215a-8fe9-4131-8200-271a7c9aee77	\N	\N	f	\N	\N	t	\N	\N
1b75a87e-95c1-417d-b3bc-3d79cb51b4e0	48.00	Plein essence	DEPENSE	2026-10-22	\N	1c27c80e-d0f4-4c7f-9dca-e1a64b378205	\N	288582f7-5be1-47cf-aaa0-17c4c453461b	3230215a-8fe9-4131-8200-271a7c9aee77	\N	\N	f	\N	\N	t	\N	\N
d53e8eef-b1d0-4796-8239-e0bcf11bfcc4	350000.00	Virement famille	RECETTE	2026-09-20	\N	1c27c80e-d0f4-4c7f-9dca-e1a64b378205	\N	5bc0341d-312f-4db9-9a75-5e3c99485d60	206d8272-0ca4-46b3-be5c-2c1da73bd704	\N	\N	f	\N	\N	t	\N	\N
51ef051a-97e9-4d72-a4f8-2f764933a670	45000.00	Marche Assigame	DEPENSE	2026-09-22	\N	1c27c80e-d0f4-4c7f-9dca-e1a64b378205	\N	8e21fade-65a0-4e5b-81fc-de5a81db9199	206d8272-0ca4-46b3-be5c-2c1da73bd704	\N	\N	f	\N	\N	t	\N	\N
ae311beb-7ae3-4c53-a7ff-1ce2c4da90c9	15000.00	Taxi-moto	DEPENSE	2026-09-24	\N	1c27c80e-d0f4-4c7f-9dca-e1a64b378205	\N	288582f7-5be1-47cf-aaa0-17c4c453461b	206d8272-0ca4-46b3-be5c-2c1da73bd704	\N	\N	f	\N	\N	t	\N	\N
f3587b08-8415-407f-a9f7-4534d4519b57	75000.00	Loyer local	DEPENSE	2026-09-19	\N	1c27c80e-d0f4-4c7f-9dca-e1a64b378205	\N	82faa757-28f9-4fd7-9854-5683407da627	206d8272-0ca4-46b3-be5c-2c1da73bd704	\N	\N	f	\N	\N	t	\N	\N
757a93b9-bf72-464e-af10-80a92100cd1c	8500.00	Pharmacie	DEPENSE	2026-09-29	\N	1c27c80e-d0f4-4c7f-9dca-e1a64b378205	\N	08be50dc-ea9e-4716-83e5-4742c5089ada	206d8272-0ca4-46b3-be5c-2c1da73bd704	\N	\N	f	\N	\N	t	\N	\N
7b9cfa4a-4331-4b37-80a9-e5918215ddb1	25000.00	Marche Hedzranawoe	DEPENSE	2026-10-03	\N	1c27c80e-d0f4-4c7f-9dca-e1a64b378205	\N	8e21fade-65a0-4e5b-81fc-de5a81db9199	206d8272-0ca4-46b3-be5c-2c1da73bd704	\N	\N	f	\N	\N	t	\N	\N
56ac37db-13fe-49c5-b71f-dcffda53c293	12000.00	Maquis	DEPENSE	2026-10-06	\N	1c27c80e-d0f4-4c7f-9dca-e1a64b378205	\N	f1ea2824-1b5a-4287-b498-d17c3e7ece24	206d8272-0ca4-46b3-be5c-2c1da73bd704	\N	\N	f	\N	\N	t	\N	\N
1f2288f9-15a5-4b44-ac85-12b3a43bb884	35000.00	Courses semaine	DEPENSE	2026-10-10	\N	1c27c80e-d0f4-4c7f-9dca-e1a64b378205	\N	79149cec-cce1-4729-86ce-556d26678b9e	206d8272-0ca4-46b3-be5c-2c1da73bd704	\N	\N	f	\N	\N	t	\N	\N
3b5c3a51-5fcc-4c02-83f8-621af31f3493	5000.00	Zem	DEPENSE	2026-10-14	\N	1c27c80e-d0f4-4c7f-9dca-e1a64b378205	\N	288582f7-5be1-47cf-aaa0-17c4c453461b	206d8272-0ca4-46b3-be5c-2c1da73bd704	\N	\N	f	\N	\N	t	\N	\N
76b2d7d9-a27a-4022-9d1a-9882e20ce68a	75000.00	Loyer local avril	DEPENSE	2026-10-20	\N	1c27c80e-d0f4-4c7f-9dca-e1a64b378205	\N	82faa757-28f9-4fd7-9854-5683407da627	206d8272-0ca4-46b3-be5c-2c1da73bd704	\N	\N	f	\N	\N	t	\N	\N
19bb3b25-8b1d-4910-b86a-161926d886ee	18500.00	Marche Assigame	DEPENSE	2026-10-21	\N	1c27c80e-d0f4-4c7f-9dca-e1a64b378205	\N	8e21fade-65a0-4e5b-81fc-de5a81db9199	206d8272-0ca4-46b3-be5c-2c1da73bd704	\N	\N	f	\N	\N	t	\N	\N
41241e0b-538d-4dbc-b24f-d459504a9ad1	3500.00	Zem trajet	DEPENSE	2026-10-21	\N	1c27c80e-d0f4-4c7f-9dca-e1a64b378205	\N	288582f7-5be1-47cf-aaa0-17c4c453461b	206d8272-0ca4-46b3-be5c-2c1da73bd704	\N	\N	f	\N	\N	t	\N	\N
9eac94d4-56c6-40b3-851b-7cab03c309d3	12000.00	Courses marche	DEPENSE	2026-10-22	\N	1c27c80e-d0f4-4c7f-9dca-e1a64b378205	\N	79149cec-cce1-4729-86ce-556d26678b9e	206d8272-0ca4-46b3-be5c-2c1da73bd704	\N	\N	f	\N	\N	t	\N	\N
6d7f9bc3-05f0-4196-acb2-e99830054387	4500.00	Maquis midi	DEPENSE	2026-10-22	\N	1c27c80e-d0f4-4c7f-9dca-e1a64b378205	\N	f1ea2824-1b5a-4287-b498-d17c3e7ece24	206d8272-0ca4-46b3-be5c-2c1da73bd704	\N	\N	f	\N	\N	t	\N	\N
e1925a88-557e-4fd1-8fd3-6e491a516c4b	750.00	Loyer	DEPENSE	2026-09-19	\N	1c27c80e-d0f4-4c7f-9dca-e1a64b378205	\N	82faa757-28f9-4fd7-9854-5683407da627	3230215a-8fe9-4131-8200-271a7c9aee77	\N	\N	t	MENSUEL	2026-10-30	t	\N	\N
6867222b-a963-4bf2-be25-c0c9b94263bc	45.00	Assurance auto	DEPENSE	2026-10-03	\N	1c27c80e-d0f4-4c7f-9dca-e1a64b378205	\N	288582f7-5be1-47cf-aaa0-17c4c453461b	3230215a-8fe9-4131-8200-271a7c9aee77	\N	\N	t	MENSUEL	2026-11-06	t	\N	\N
c65d273d-5c7c-4454-877f-cc5cc174478e	2800.00	Salaire	RECETTE	2026-10-22	\N	1c27c80e-d0f4-4c7f-9dca-e1a64b378205	\N	5bc0341d-312f-4db9-9a75-5e3c99485d60	3230215a-8fe9-4131-8200-271a7c9aee77	\N	\N	f	\N	\N	t	\N	\N
ea810606-c3be-42e1-9d77-28b489179cbd	620.00	Mission freelance	RECETTE	2026-10-23	Client Mensah	1c27c80e-d0f4-4c7f-9dca-e1a64b378205	\N	b786ff41-9735-4f66-a9d4-b8d8e26c02e2	3230215a-8fe9-4131-8200-271a7c9aee77	\N	\N	f	\N	\N	t	\N	\N
f23d2cae-583e-4bfd-a617-a3102e9ef50a	2800.00	March salary	RECETTE	2026-09-19	\N	ad2f63f8-5fb7-4266-bf3c-3972c03e3714	\N	dea77827-e7b6-421a-bc94-0b2506bffc80	1739ae09-4a3e-4779-8943-e3a6bb4bdbee	\N	\N	f	\N	\N	t	\N	\N
cd1557d0-0be2-46d4-8597-d55dc0fb90e1	450.00	Freelance assignment	RECETTE	2026-09-28	Client Dupont	ad2f63f8-5fb7-4266-bf3c-3972c03e3714	\N	ec7a868c-874f-41a0-bb77-45f2f9828775	1739ae09-4a3e-4779-8943-e3a6bb4bdbee	\N	\N	f	\N	\N	t	\N	\N
1b72200f-334e-42c9-bf1f-d554b818b92c	750.00	March rent	DEPENSE	2026-09-19	\N	ad2f63f8-5fb7-4266-bf3c-3972c03e3714	\N	12183a1c-9d4b-4335-aa84-39763cc0e18a	1739ae09-4a3e-4779-8943-e3a6bb4bdbee	\N	\N	f	\N	\N	t	\N	\N
3dabf9a8-f5fa-4d66-8497-db2e3c3a0d2a	85.50	Carrefour	DEPENSE	2026-09-21	\N	ad2f63f8-5fb7-4266-bf3c-3972c03e3714	\N	14655205-689b-4285-9b04-acfac5e7c169	1739ae09-4a3e-4779-8943-e3a6bb4bdbee	\N	\N	f	\N	\N	t	\N	\N
a31ee326-1697-49d3-9e1e-3931f64adf2d	42.00	Fuel	DEPENSE	2026-09-23	\N	ad2f63f8-5fb7-4266-bf3c-3972c03e3714	\N	f17aa566-36a8-4255-b2ed-4bb5f20a4b3e	1739ae09-4a3e-4779-8943-e3a6bb4bdbee	\N	\N	f	\N	\N	t	\N	\N
fd154f78-6dab-46cf-8794-52e2b8725b87	120.00	Doctor + pharmacy	DEPENSE	2026-09-25	\N	ad2f63f8-5fb7-4266-bf3c-3972c03e3714	\N	f5fb2807-184b-42af-9f9b-b41e1b21b8ce	1739ae09-4a3e-4779-8943-e3a6bb4bdbee	\N	\N	f	\N	\N	t	\N	\N
6fdc062d-c471-4a57-b01d-ba5b80dedb19	35.90	Lidl	DEPENSE	2026-09-27	\N	ad2f63f8-5fb7-4266-bf3c-3972c03e3714	\N	24418c02-db83-43f1-bc6f-c500c30cf081	1739ae09-4a3e-4779-8943-e3a6bb4bdbee	\N	\N	f	\N	\N	t	\N	\N
63d668f9-bd96-4874-8078-8d215524e779	28.50	Sushi Shop	DEPENSE	2026-09-30	\N	ad2f63f8-5fb7-4266-bf3c-3972c03e3714	\N	7dc4e56f-56d4-4c82-af6d-8a76a5771c1e	1739ae09-4a3e-4779-8943-e3a6bb4bdbee	\N	\N	f	\N	\N	t	\N	\N
8437e02f-26dd-4cd4-8f84-2d59f91a386f	65.00	Cinema + bowling	DEPENSE	2026-10-03	\N	ad2f63f8-5fb7-4266-bf3c-3972c03e3714	\N	f9123ad2-9fcb-4011-bfe0-c2e6626683fa	1739ae09-4a3e-4779-8943-e3a6bb4bdbee	\N	\N	f	\N	\N	t	\N	\N
8512b5db-cdf6-4208-9f7b-35dd15b8bd82	92.30	Weekly groceries	DEPENSE	2026-10-05	\N	ad2f63f8-5fb7-4266-bf3c-3972c03e3714	\N	14655205-689b-4285-9b04-acfac5e7c169	1739ae09-4a3e-4779-8943-e3a6bb4bdbee	\N	\N	f	\N	\N	t	\N	\N
b6a7a4dc-0b3b-484c-86a4-4c486df40a56	15.00	Uber	DEPENSE	2026-10-07	\N	ad2f63f8-5fb7-4266-bf3c-3972c03e3714	\N	f17aa566-36a8-4255-b2ed-4bb5f20a4b3e	1739ae09-4a3e-4779-8943-e3a6bb4bdbee	\N	\N	f	\N	\N	t	\N	\N
d01a8cbd-d6b6-4a4f-a743-bbf4ce5c5d67	48.00	Italian restaurant	DEPENSE	2026-10-10	\N	ad2f63f8-5fb7-4266-bf3c-3972c03e3714	\N	7dc4e56f-56d4-4c82-af6d-8a76a5771c1e	1739ae09-4a3e-4779-8943-e3a6bb4bdbee	\N	\N	f	\N	\N	t	\N	\N
d9968810-b23e-4e53-9a1a-a59068ce950f	110.00	Auchan groceries	DEPENSE	2026-10-13	\N	ad2f63f8-5fb7-4266-bf3c-3972c03e3714	\N	14655205-689b-4285-9b04-acfac5e7c169	1739ae09-4a3e-4779-8943-e3a6bb4bdbee	\N	\N	f	\N	\N	t	\N	\N
5a229093-eece-4e66-bfaa-0537e3ff8b28	55.00	Full tank	DEPENSE	2026-10-16	\N	ad2f63f8-5fb7-4266-bf3c-3972c03e3714	\N	f17aa566-36a8-4255-b2ed-4bb5f20a4b3e	1739ae09-4a3e-4779-8943-e3a6bb4bdbee	\N	\N	f	\N	\N	t	\N	\N
cb5c1f13-3717-46e5-90dd-8f320ab6de39	2800.00	February salary	RECETTE	2026-08-22	\N	ad2f63f8-5fb7-4266-bf3c-3972c03e3714	\N	dea77827-e7b6-421a-bc94-0b2506bffc80	1739ae09-4a3e-4779-8943-e3a6bb4bdbee	\N	\N	f	\N	\N	t	\N	\N
9e2ae55f-ad6f-44b7-b686-5e4392fbbe24	750.00	February rent	DEPENSE	2026-08-22	\N	ad2f63f8-5fb7-4266-bf3c-3972c03e3714	\N	12183a1c-9d4b-4335-aa84-39763cc0e18a	1739ae09-4a3e-4779-8943-e3a6bb4bdbee	\N	\N	f	\N	\N	t	\N	\N
54d9390d-edc8-49dc-9024-c4a5f2762826	95.00	Carrefour groceries	DEPENSE	2026-08-25	\N	ad2f63f8-5fb7-4266-bf3c-3972c03e3714	\N	14655205-689b-4285-9b04-acfac5e7c169	1739ae09-4a3e-4779-8943-e3a6bb4bdbee	\N	\N	f	\N	\N	t	\N	\N
28812b04-5522-427c-9c72-14e6d4a8f023	38.00	Fuel	DEPENSE	2026-08-29	\N	ad2f63f8-5fb7-4266-bf3c-3972c03e3714	\N	f17aa566-36a8-4255-b2ed-4bb5f20a4b3e	1739ae09-4a3e-4779-8943-e3a6bb4bdbee	\N	\N	f	\N	\N	t	\N	\N
53650cc7-e3e0-484f-9ef2-9ad473167462	22.00	Kebab + tacos	DEPENSE	2026-08-31	\N	ad2f63f8-5fb7-4266-bf3c-3972c03e3714	\N	7dc4e56f-56d4-4c82-af6d-8a76a5771c1e	1739ae09-4a3e-4779-8943-e3a6bb4bdbee	\N	\N	f	\N	\N	t	\N	\N
28b60dd0-3d1b-4c37-aa76-ee30ba056c10	180.00	Dentist	DEPENSE	2026-09-04	\N	ad2f63f8-5fb7-4266-bf3c-3972c03e3714	\N	f5fb2807-184b-42af-9f9b-b41e1b21b8ce	1739ae09-4a3e-4779-8943-e3a6bb4bdbee	\N	\N	f	\N	\N	t	\N	\N
1375896d-19a1-478e-9eb7-cd59d6a7d15d	73.50	Weekly groceries	DEPENSE	2026-09-08	\N	ad2f63f8-5fb7-4266-bf3c-3972c03e3714	\N	14655205-689b-4285-9b04-acfac5e7c169	1739ae09-4a3e-4779-8943-e3a6bb4bdbee	\N	\N	f	\N	\N	t	\N	\N
0d66cc86-f84c-4104-9bc8-712c567640b0	40.00	Video games	DEPENSE	2026-09-11	\N	ad2f63f8-5fb7-4266-bf3c-3972c03e3714	\N	f9123ad2-9fcb-4011-bfe0-c2e6626683fa	1739ae09-4a3e-4779-8943-e3a6bb4bdbee	\N	\N	f	\N	\N	t	\N	\N
8444f0e6-c003-4f61-8c8c-b0d96bee46e2	52.00	Full tank	DEPENSE	2026-09-15	\N	ad2f63f8-5fb7-4266-bf3c-3972c03e3714	\N	f17aa566-36a8-4255-b2ed-4bb5f20a4b3e	1739ae09-4a3e-4779-8943-e3a6bb4bdbee	\N	\N	f	\N	\N	t	\N	\N
44d197ce-8aed-44cf-a80b-82833d13fe72	2800.00	April salary	RECETTE	2026-10-20	\N	ad2f63f8-5fb7-4266-bf3c-3972c03e3714	\N	dea77827-e7b6-421a-bc94-0b2506bffc80	1739ae09-4a3e-4779-8943-e3a6bb4bdbee	\N	\N	f	\N	\N	t	\N	\N
e3a95b91-5377-4961-8fc5-d604d1f5b18a	750.00	April rent	DEPENSE	2026-10-20	\N	ad2f63f8-5fb7-4266-bf3c-3972c03e3714	\N	12183a1c-9d4b-4335-aa84-39763cc0e18a	1739ae09-4a3e-4779-8943-e3a6bb4bdbee	\N	\N	f	\N	\N	t	\N	\N
ed346d09-8093-41de-a579-7215d652ad6e	29.99	Orange Fibre	DEPENSE	2026-10-20	Direct debit	ad2f63f8-5fb7-4266-bf3c-3972c03e3714	\N	85c8b18b-577f-46af-a6d6-de115f2c2b74	1739ae09-4a3e-4779-8943-e3a6bb4bdbee	\N	\N	f	\N	\N	t	\N	\N
dd52d0a2-b10c-4eb9-b1e0-1dc4824dce04	67.40	Carrefour Market	DEPENSE	2026-10-21	\N	ad2f63f8-5fb7-4266-bf3c-3972c03e3714	\N	14655205-689b-4285-9b04-acfac5e7c169	1739ae09-4a3e-4779-8943-e3a6bb4bdbee	\N	\N	f	\N	\N	t	\N	\N
fb2700db-fae8-42d5-8659-47f108fb9079	1.90	Metro ticket	DEPENSE	2026-10-21	\N	ad2f63f8-5fb7-4266-bf3c-3972c03e3714	\N	f17aa566-36a8-4255-b2ed-4bb5f20a4b3e	1739ae09-4a3e-4779-8943-e3a6bb4bdbee	\N	\N	f	\N	\N	t	\N	\N
ae890512-30a1-47e5-b42d-79d0dadf1c4b	12.50	Bakery	DEPENSE	2026-10-21	\N	ad2f63f8-5fb7-4266-bf3c-3972c03e3714	\N	14655205-689b-4285-9b04-acfac5e7c169	1739ae09-4a3e-4779-8943-e3a6bb4bdbee	\N	\N	f	\N	\N	t	\N	\N
6f9de44b-c318-4849-941e-1bc00e709eb8	14.90	Kebab lunch	DEPENSE	2026-10-22	\N	ad2f63f8-5fb7-4266-bf3c-3972c03e3714	\N	7dc4e56f-56d4-4c82-af6d-8a76a5771c1e	1739ae09-4a3e-4779-8943-e3a6bb4bdbee	\N	\N	f	\N	\N	t	\N	\N
ad9388f3-bb48-475c-bd45-c31acbb32ad6	43.20	Lidl	DEPENSE	2026-10-22	\N	ad2f63f8-5fb7-4266-bf3c-3972c03e3714	\N	24418c02-db83-43f1-bc6f-c500c30cf081	1739ae09-4a3e-4779-8943-e3a6bb4bdbee	\N	\N	f	\N	\N	t	\N	\N
5cdb8b16-609b-40bc-bdb7-4d2dc0a5862c	48.00	Full tank	DEPENSE	2026-10-22	\N	ad2f63f8-5fb7-4266-bf3c-3972c03e3714	\N	f17aa566-36a8-4255-b2ed-4bb5f20a4b3e	1739ae09-4a3e-4779-8943-e3a6bb4bdbee	\N	\N	f	\N	\N	t	\N	\N
2c123ce5-5400-4931-b025-990ad694910c	350000.00	Family transfer	RECETTE	2026-09-20	\N	ad2f63f8-5fb7-4266-bf3c-3972c03e3714	\N	dea77827-e7b6-421a-bc94-0b2506bffc80	52b510ad-bade-4137-8c1a-fcabfe7980cc	\N	\N	f	\N	\N	t	\N	\N
45be05a3-84ca-45cd-acc6-9c4b31114ac9	45000.00	Assigame market	DEPENSE	2026-09-22	\N	ad2f63f8-5fb7-4266-bf3c-3972c03e3714	\N	14655205-689b-4285-9b04-acfac5e7c169	52b510ad-bade-4137-8c1a-fcabfe7980cc	\N	\N	f	\N	\N	t	\N	\N
ec499b13-f17d-4aa4-bc8c-15fb48b00542	15000.00	Motorbike taxi	DEPENSE	2026-09-24	\N	ad2f63f8-5fb7-4266-bf3c-3972c03e3714	\N	f17aa566-36a8-4255-b2ed-4bb5f20a4b3e	52b510ad-bade-4137-8c1a-fcabfe7980cc	\N	\N	f	\N	\N	t	\N	\N
3b850fc8-5bf9-48e2-b128-955c969637ec	75000.00	Local rent	DEPENSE	2026-09-19	\N	ad2f63f8-5fb7-4266-bf3c-3972c03e3714	\N	12183a1c-9d4b-4335-aa84-39763cc0e18a	52b510ad-bade-4137-8c1a-fcabfe7980cc	\N	\N	f	\N	\N	t	\N	\N
c3143dea-a760-456d-ab3c-0ed55308b8dc	8500.00	Pharmacy	DEPENSE	2026-09-29	\N	ad2f63f8-5fb7-4266-bf3c-3972c03e3714	\N	f5fb2807-184b-42af-9f9b-b41e1b21b8ce	52b510ad-bade-4137-8c1a-fcabfe7980cc	\N	\N	f	\N	\N	t	\N	\N
c271b7b1-3254-4d55-adc8-6d44f9c58db9	25000.00	Hedzranawoe market	DEPENSE	2026-10-03	\N	ad2f63f8-5fb7-4266-bf3c-3972c03e3714	\N	14655205-689b-4285-9b04-acfac5e7c169	52b510ad-bade-4137-8c1a-fcabfe7980cc	\N	\N	f	\N	\N	t	\N	\N
5fea7f26-dfc7-4493-976c-3f6f3eab94e5	12000.00	Maquis	DEPENSE	2026-10-06	\N	ad2f63f8-5fb7-4266-bf3c-3972c03e3714	\N	7dc4e56f-56d4-4c82-af6d-8a76a5771c1e	52b510ad-bade-4137-8c1a-fcabfe7980cc	\N	\N	f	\N	\N	t	\N	\N
a158baa1-69df-40a4-b03e-5f840129e0bf	35000.00	Weekly groceries	DEPENSE	2026-10-10	\N	ad2f63f8-5fb7-4266-bf3c-3972c03e3714	\N	24418c02-db83-43f1-bc6f-c500c30cf081	52b510ad-bade-4137-8c1a-fcabfe7980cc	\N	\N	f	\N	\N	t	\N	\N
7a5d391c-ecb5-464c-a81c-0058a123f422	5000.00	Zem	DEPENSE	2026-10-14	\N	ad2f63f8-5fb7-4266-bf3c-3972c03e3714	\N	f17aa566-36a8-4255-b2ed-4bb5f20a4b3e	52b510ad-bade-4137-8c1a-fcabfe7980cc	\N	\N	f	\N	\N	t	\N	\N
a0a987ca-acbc-4661-a31d-f5fab947f745	75000.00	April local rent	DEPENSE	2026-10-20	\N	ad2f63f8-5fb7-4266-bf3c-3972c03e3714	\N	12183a1c-9d4b-4335-aa84-39763cc0e18a	52b510ad-bade-4137-8c1a-fcabfe7980cc	\N	\N	f	\N	\N	t	\N	\N
d6635187-e34c-4ec2-a2e5-29279fad0e74	18500.00	Assigame market	DEPENSE	2026-10-21	\N	ad2f63f8-5fb7-4266-bf3c-3972c03e3714	\N	14655205-689b-4285-9b04-acfac5e7c169	52b510ad-bade-4137-8c1a-fcabfe7980cc	\N	\N	f	\N	\N	t	\N	\N
9a77d3e2-a889-4c11-9005-249161b68f28	3500.00	Zem ride	DEPENSE	2026-10-21	\N	ad2f63f8-5fb7-4266-bf3c-3972c03e3714	\N	f17aa566-36a8-4255-b2ed-4bb5f20a4b3e	52b510ad-bade-4137-8c1a-fcabfe7980cc	\N	\N	f	\N	\N	t	\N	\N
6c45d457-a356-460b-8e73-737fcaca1949	12000.00	Market groceries	DEPENSE	2026-10-22	\N	ad2f63f8-5fb7-4266-bf3c-3972c03e3714	\N	24418c02-db83-43f1-bc6f-c500c30cf081	52b510ad-bade-4137-8c1a-fcabfe7980cc	\N	\N	f	\N	\N	t	\N	\N
8d0a6fdb-86e1-4194-b77e-1edc365d8dd0	4500.00	Maquis lunch	DEPENSE	2026-10-22	\N	ad2f63f8-5fb7-4266-bf3c-3972c03e3714	\N	7dc4e56f-56d4-4c82-af6d-8a76a5771c1e	52b510ad-bade-4137-8c1a-fcabfe7980cc	\N	\N	f	\N	\N	t	\N	\N
bac70b6c-b872-44cc-8341-0e348a516573	750.00	Rent	DEPENSE	2026-09-19	\N	ad2f63f8-5fb7-4266-bf3c-3972c03e3714	\N	12183a1c-9d4b-4335-aa84-39763cc0e18a	1739ae09-4a3e-4779-8943-e3a6bb4bdbee	\N	\N	t	MENSUEL	2026-10-30	t	\N	\N
8c382459-a945-4db1-ba18-92ed51593df8	45.00	Car insurance	DEPENSE	2026-10-03	\N	ad2f63f8-5fb7-4266-bf3c-3972c03e3714	\N	f17aa566-36a8-4255-b2ed-4bb5f20a4b3e	1739ae09-4a3e-4779-8943-e3a6bb4bdbee	\N	\N	t	MENSUEL	2026-11-06	t	\N	\N
c6f4e80c-8bac-495c-bd97-32030362f153	2800.00	Salary	RECETTE	2026-10-22	\N	ad2f63f8-5fb7-4266-bf3c-3972c03e3714	\N	dea77827-e7b6-421a-bc94-0b2506bffc80	1739ae09-4a3e-4779-8943-e3a6bb4bdbee	\N	\N	f	\N	\N	t	\N	\N
193bb38b-76ea-4110-a6c9-bb51dd58806a	620.00	Freelance assignment	RECETTE	2026-10-23	Client Mensah	ad2f63f8-5fb7-4266-bf3c-3972c03e3714	\N	ec7a868c-874f-41a0-bb77-45f2f9828775	1739ae09-4a3e-4779-8943-e3a6bb4bdbee	\N	\N	f	\N	\N	t	\N	\N
75756e67-ab7d-4972-9fd3-734fd550e453	2100.00	Salaire	RECETTE	2026-10-20	\N	4574530e-bf91-47af-a17f-1926168199fe	\N	472f92c5-6b44-4ce9-b909-067e316692f7	082bef8a-76b8-4aac-aa0f-a4e6bd5c0a67	\N	\N	f	\N	\N	t	\N	\N
c11d9af1-9d0a-4597-a8b6-90de848afc40	78.40	Courses	DEPENSE	2026-09-30	\N	4574530e-bf91-47af-a17f-1926168199fe	\N	51c0d8f9-22cd-4922-af1b-f8941b18eb17	082bef8a-76b8-4aac-aa0f-a4e6bd5c0a67	\N	\N	f	\N	\N	t	\N	\N
a84b3554-57c5-4b33-bc5d-2f29eb698086	2100.00	Salaire	RECETTE	2026-10-22	\N	4574530e-bf91-47af-a17f-1926168199fe	\N	472f92c5-6b44-4ce9-b909-067e316692f7	082bef8a-76b8-4aac-aa0f-a4e6bd5c0a67	\N	\N	f	\N	\N	t	\N	\N
667b1994-d81c-4621-a5ef-c7a0ce008e31	61.20	Courses	DEPENSE	2026-10-23	\N	4574530e-bf91-47af-a17f-1926168199fe	\N	51c0d8f9-22cd-4922-af1b-f8941b18eb17	082bef8a-76b8-4aac-aa0f-a4e6bd5c0a67	\N	\N	f	\N	\N	t	\N	\N
7aafec79-2214-4610-a0df-d7cb7c0438d6	2100.00	Salaire	RECETTE	2026-10-20	\N	ef82fe3c-c290-4056-b04c-7560acee05ed	\N	ee8fb6a5-2532-4fc0-b236-597b931a17b1	e59917e7-e1d7-4eb2-8d91-57b9fb2812ac	\N	\N	f	\N	\N	t	\N	\N
52fb3798-401e-4c80-a625-797e15a74c09	78.40	Courses	DEPENSE	2026-09-30	\N	ef82fe3c-c290-4056-b04c-7560acee05ed	\N	9eb46ec9-6761-4227-a5a1-bfa8383e76dc	e59917e7-e1d7-4eb2-8d91-57b9fb2812ac	\N	\N	f	\N	\N	t	\N	\N
fcdd94c4-0ce3-4cca-9e4e-5fcad80a30f0	2100.00	Salaire	RECETTE	2026-10-22	\N	ef82fe3c-c290-4056-b04c-7560acee05ed	\N	ee8fb6a5-2532-4fc0-b236-597b931a17b1	e59917e7-e1d7-4eb2-8d91-57b9fb2812ac	\N	\N	f	\N	\N	t	\N	\N
2afa98d2-ba6b-46b9-a0c1-828ca4830d55	61.20	Courses	DEPENSE	2026-10-23	\N	ef82fe3c-c290-4056-b04c-7560acee05ed	\N	9eb46ec9-6761-4227-a5a1-bfa8383e76dc	e59917e7-e1d7-4eb2-8d91-57b9fb2812ac	\N	\N	f	\N	\N	t	\N	\N
\.


--
-- Data for Name: user_preferences; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.user_preferences (id, user_id, enabled_features, nav_order, updated_at, currencies, enabled_notification_types, timezone, text_scale, language) FROM stdin;
332be105-a3d5-4c02-8743-f23b10e70aec	1c27c80e-d0f4-4c7f-9dca-e1a64b378205	SUBSCRIPTIONS,DEBTS,BUDGETS	SUBSCRIPTIONS,DEBTS,BUDGETS	2026-10-25 23:26:01.32167	EUR,XOF	\N	Europe/Paris	MEDIUM	\N
b28b9115-5eca-46e0-9e7e-5a20b15de35a	ad2f63f8-5fb7-4266-bf3c-3972c03e3714	SUBSCRIPTIONS,DEBTS,BUDGETS	SUBSCRIPTIONS,DEBTS,BUDGETS	2026-10-25 23:26:01.32167	EUR,XOF	\N	Europe/Paris	MEDIUM	en
c3e63dab-fe9b-4f85-b88d-99b78f0caa0d	4574530e-bf91-47af-a17f-1926168199fe	SUBSCRIPTIONS,DEBTS,BUDGETS	SUBSCRIPTIONS,DEBTS,BUDGETS	2026-10-25 23:26:01.32167	EUR	\N	Europe/Paris	MEDIUM	\N
8418795b-c4ef-4803-b964-4c2140052332	ef82fe3c-c290-4056-b04c-7560acee05ed	SUBSCRIPTIONS,DEBTS,BUDGETS	SUBSCRIPTIONS,DEBTS,BUDGETS	2026-10-25 23:26:01.32167	EUR	\N	Europe/Paris	MEDIUM	\N
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.users (id, email, password, name, created_at, disabled_at, is_admin, password_reset_required, avatar_path) FROM stdin;
1c27c80e-d0f4-4c7f-9dca-e1a64b378205	dev@local.test	$2a$10$bRDCPqItSOFJNMihfnz3Eu3CBZC9jc0/ZtzSnLYDcdI4rm8AO2rKq	Dev User	2026-10-25 23:26:01.32167	\N	f	f	\N
ad2f63f8-5fb7-4266-bf3c-3972c03e3714	demo@local.test	$2a$10$bRDCPqItSOFJNMihfnz3Eu3CBZC9jc0/ZtzSnLYDcdI4rm8AO2rKq	Alex Morgan	2026-10-25 23:26:01.32167	\N	f	f	\N
4574530e-bf91-47af-a17f-1926168199fe	admin@local.test	$2a$10$bRDCPqItSOFJNMihfnz3Eu3CBZC9jc0/ZtzSnLYDcdI4rm8AO2rKq	Amina Diallo	2026-07-27 23:26:01.32167	\N	t	f	\N
ef82fe3c-c290-4056-b04c-7560acee05ed	invite@local.test	$2a$10$bRDCPqItSOFJNMihfnz3Eu3CBZC9jc0/ZtzSnLYDcdI4rm8AO2rKq	Thomas Berger	2026-10-13 23:26:01.32167	\N	f	f	\N
\.


--
-- Name: invitation_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.invitation_id_seq', 1, false);


--
-- Name: accounts accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts
    ADD CONSTRAINT accounts_pkey PRIMARY KEY (id);


--
-- Name: budget_snapshots budget_snapshots_mois_category_id_user_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.budget_snapshots
    ADD CONSTRAINT budget_snapshots_mois_category_id_user_id_key UNIQUE (mois, category_id, user_id);


--
-- Name: budget_snapshots budget_snapshots_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.budget_snapshots
    ADD CONSTRAINT budget_snapshots_pkey PRIMARY KEY (id);


--
-- Name: budgets budgets_category_id_user_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.budgets
    ADD CONSTRAINT budgets_category_id_user_id_key UNIQUE (category_id, user_id);


--
-- Name: budgets budgets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.budgets
    ADD CONSTRAINT budgets_pkey PRIMARY KEY (id);


--
-- Name: categories categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (id);


--
-- Name: category_rules category_rules_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.category_rules
    ADD CONSTRAINT category_rules_pkey PRIMARY KEY (id);


--
-- Name: category_rules category_rules_user_id_pattern_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.category_rules
    ADD CONSTRAINT category_rules_user_id_pattern_key UNIQUE (user_id, pattern);


--
-- Name: debts debts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.debts
    ADD CONSTRAINT debts_pkey PRIMARY KEY (id);


--
-- Name: exchange_rates exchange_rates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exchange_rates
    ADD CONSTRAINT exchange_rates_pkey PRIMARY KEY (id);


--
-- Name: exchange_rates exchange_rates_user_id_base_currency_target_currency_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exchange_rates
    ADD CONSTRAINT exchange_rates_user_id_base_currency_target_currency_key UNIQUE (user_id, base_currency, target_currency);


--
-- Name: flyway_schema_history flyway_schema_history_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flyway_schema_history
    ADD CONSTRAINT flyway_schema_history_pk PRIMARY KEY (installed_rank);


--
-- Name: import_draft_lines import_draft_lines_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.import_draft_lines
    ADD CONSTRAINT import_draft_lines_pkey PRIMARY KEY (id);


--
-- Name: import_drafts import_drafts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.import_drafts
    ADD CONSTRAINT import_drafts_pkey PRIMARY KEY (id);


--
-- Name: import_history import_history_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.import_history
    ADD CONSTRAINT import_history_pkey PRIMARY KEY (id);


--
-- Name: import_profiles import_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.import_profiles
    ADD CONSTRAINT import_profiles_pkey PRIMARY KEY (id);


--
-- Name: invitation invitation_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invitation
    ADD CONSTRAINT invitation_pkey PRIMARY KEY (id);


--
-- Name: invitation invitation_token_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invitation
    ADD CONSTRAINT invitation_token_key UNIQUE (token);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: refresh_tokens refresh_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.refresh_tokens
    ADD CONSTRAINT refresh_tokens_pkey PRIMARY KEY (id);


--
-- Name: subscriptions subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_pkey PRIMARY KEY (id);


--
-- Name: transactions transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_pkey PRIMARY KEY (id);


--
-- Name: user_preferences user_preferences_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_preferences
    ADD CONSTRAINT user_preferences_pkey PRIMARY KEY (id);


--
-- Name: user_preferences user_preferences_user_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_preferences
    ADD CONSTRAINT user_preferences_user_id_key UNIQUE (user_id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: flyway_schema_history_s_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX flyway_schema_history_s_idx ON public.flyway_schema_history USING btree (success);


--
-- Name: idx_accounts_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_accounts_user_id ON public.accounts USING btree (user_id);


--
-- Name: idx_budgets_category_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_budgets_category_id ON public.budgets USING btree (category_id);


--
-- Name: idx_budgets_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_budgets_user_id ON public.budgets USING btree (user_id);


--
-- Name: idx_categories_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_categories_user_id ON public.categories USING btree (user_id);


--
-- Name: idx_category_rules_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_category_rules_user ON public.category_rules USING btree (user_id);


--
-- Name: idx_debts_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_debts_account_id ON public.debts USING btree (account_id);


--
-- Name: idx_debts_category_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_debts_category_id ON public.debts USING btree (category_id);


--
-- Name: idx_debts_reminder; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_debts_reminder ON public.debts USING btree (reminder_date, reminder_time) WHERE (reminder_date IS NOT NULL);


--
-- Name: idx_debts_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_debts_user_id ON public.debts USING btree (user_id);


--
-- Name: idx_exchange_rates_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_exchange_rates_user ON public.exchange_rates USING btree (user_id);


--
-- Name: idx_import_draft_lines_draft; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_import_draft_lines_draft ON public.import_draft_lines USING btree (draft_id);


--
-- Name: idx_import_drafts_user_account; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_import_drafts_user_account ON public.import_drafts USING btree (user_id, account_id);


--
-- Name: idx_import_history_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_import_history_user ON public.import_history USING btree (user_id);


--
-- Name: idx_import_profiles_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_import_profiles_user ON public.import_profiles USING btree (user_id);


--
-- Name: idx_invitation_token; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_invitation_token ON public.invitation USING btree (token);


--
-- Name: idx_notifications_user_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notifications_user_created ON public.notifications USING btree (user_id, created_at DESC);


--
-- Name: idx_notifications_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notifications_user_id ON public.notifications USING btree (user_id);


--
-- Name: idx_notifications_user_read; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notifications_user_read ON public.notifications USING btree (user_id, read);


--
-- Name: idx_refresh_tokens_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_refresh_tokens_status ON public.refresh_tokens USING btree (status);


--
-- Name: idx_refresh_tokens_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_refresh_tokens_user_id ON public.refresh_tokens USING btree (user_id);


--
-- Name: idx_snapshots_category_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_snapshots_category_id ON public.budget_snapshots USING btree (category_id);


--
-- Name: idx_snapshots_mois; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_snapshots_mois ON public.budget_snapshots USING btree (mois);


--
-- Name: idx_snapshots_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_snapshots_user_id ON public.budget_snapshots USING btree (user_id);


--
-- Name: idx_subscriptions_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_subscriptions_account_id ON public.subscriptions USING btree (account_id);


--
-- Name: idx_subscriptions_category_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_subscriptions_category_id ON public.subscriptions USING btree (category_id);


--
-- Name: idx_subscriptions_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_subscriptions_user_id ON public.subscriptions USING btree (user_id);


--
-- Name: idx_transactions_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transactions_account_id ON public.transactions USING btree (account_id);


--
-- Name: idx_transactions_account_import_fingerprint; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transactions_account_import_fingerprint ON public.transactions USING btree (account_id, import_fingerprint);


--
-- Name: idx_transactions_category_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transactions_category_id ON public.transactions USING btree (category_id);


--
-- Name: idx_transactions_debt_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transactions_debt_id ON public.transactions USING btree (debt_id);


--
-- Name: idx_transactions_recurring_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transactions_recurring_active ON public.transactions USING btree (user_id, next_occurrence) WHERE ((is_recurring = true) AND (recurring_active = true));


--
-- Name: idx_transactions_subscription_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transactions_subscription_id ON public.transactions USING btree (subscription_id) WHERE (subscription_id IS NOT NULL);


--
-- Name: idx_transactions_transfer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transactions_transfer_id ON public.transactions USING btree (transfer_id) WHERE (transfer_id IS NOT NULL);


--
-- Name: idx_transactions_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transactions_user_id ON public.transactions USING btree (user_id);


--
-- Name: uq_accounts_nom_user; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_accounts_nom_user ON public.accounts USING btree (lower((nom)::text), user_id) WHERE (actif = true);


--
-- Name: uq_categories_nom_user; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_categories_nom_user ON public.categories USING btree (lower((nom)::text), user_id);


--
-- Name: uq_categories_system_key_user; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_categories_system_key_user ON public.categories USING btree (user_id, system_key) WHERE (system_key IS NOT NULL);


--
-- Name: uq_refresh_tokens_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_refresh_tokens_token ON public.refresh_tokens USING btree (token);


--
-- Name: accounts accounts_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts
    ADD CONSTRAINT accounts_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: budget_snapshots budget_snapshots_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.budget_snapshots
    ADD CONSTRAINT budget_snapshots_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.categories(id) ON DELETE CASCADE;


--
-- Name: budgets budgets_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.budgets
    ADD CONSTRAINT budgets_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.categories(id) ON DELETE CASCADE;


--
-- Name: category_rules category_rules_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.category_rules
    ADD CONSTRAINT category_rules_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.categories(id) ON DELETE CASCADE;


--
-- Name: category_rules category_rules_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.category_rules
    ADD CONSTRAINT category_rules_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: debts debts_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.debts
    ADD CONSTRAINT debts_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE SET NULL;


--
-- Name: exchange_rates exchange_rates_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exchange_rates
    ADD CONSTRAINT exchange_rates_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: budget_snapshots fk_budget_snapshots_user; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.budget_snapshots
    ADD CONSTRAINT fk_budget_snapshots_user FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: budgets fk_budgets_user; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.budgets
    ADD CONSTRAINT fk_budgets_user FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: categories fk_categories_user; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT fk_categories_user FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: debts fk_debts_category; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.debts
    ADD CONSTRAINT fk_debts_category FOREIGN KEY (category_id) REFERENCES public.categories(id) ON DELETE SET NULL;


--
-- Name: debts fk_debts_user; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.debts
    ADD CONSTRAINT fk_debts_user FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: refresh_tokens fk_refresh_tokens_user; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.refresh_tokens
    ADD CONSTRAINT fk_refresh_tokens_user FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: subscriptions fk_subscriptions_account; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT fk_subscriptions_account FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE SET NULL;


--
-- Name: subscriptions fk_subscriptions_category; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT fk_subscriptions_category FOREIGN KEY (category_id) REFERENCES public.categories(id) ON DELETE SET NULL;


--
-- Name: subscriptions fk_subscriptions_user; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT fk_subscriptions_user FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: transactions fk_transactions_account; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT fk_transactions_account FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: transactions fk_transactions_category; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT fk_transactions_category FOREIGN KEY (category_id) REFERENCES public.categories(id) ON DELETE SET NULL;


--
-- Name: transactions fk_transactions_user; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT fk_transactions_user FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: import_draft_lines import_draft_lines_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.import_draft_lines
    ADD CONSTRAINT import_draft_lines_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.categories(id);


--
-- Name: import_draft_lines import_draft_lines_draft_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.import_draft_lines
    ADD CONSTRAINT import_draft_lines_draft_id_fkey FOREIGN KEY (draft_id) REFERENCES public.import_drafts(id) ON DELETE CASCADE;


--
-- Name: import_drafts import_drafts_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.import_drafts
    ADD CONSTRAINT import_drafts_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: import_drafts import_drafts_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.import_drafts
    ADD CONSTRAINT import_drafts_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: import_history import_history_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.import_history
    ADD CONSTRAINT import_history_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: import_history import_history_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.import_history
    ADD CONSTRAINT import_history_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: import_profiles import_profiles_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.import_profiles
    ADD CONSTRAINT import_profiles_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: invitation invitation_invited_by_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invitation
    ADD CONSTRAINT invitation_invited_by_user_id_fkey FOREIGN KEY (invited_by_user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: notifications notifications_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: transactions transactions_debt_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_debt_id_fkey FOREIGN KEY (debt_id) REFERENCES public.debts(id) ON DELETE SET NULL;


--
-- Name: transactions transactions_subscription_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_subscription_id_fkey FOREIGN KEY (subscription_id) REFERENCES public.subscriptions(id);


--
-- Name: user_preferences user_preferences_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_preferences
    ADD CONSTRAINT user_preferences_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict iVEnAqEzep6J6bJd41ihEHRnfhfO7ZYjO7uzyres4JdUuWToDRcgh58CGdZ6pZl

