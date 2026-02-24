CREATE TABLE public.app_dependencies (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    app_id uuid,
    depends_on_app_id uuid
);
CREATE TABLE public.apps (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    key text NOT NULL,
    name text NOT NULL,
    has_api boolean DEFAULT true,
    is_core boolean DEFAULT false
);
CREATE TABLE public.employees (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    first_name text NOT NULL,
    last_name text NOT NULL,
    personal_email text,
    corp_email text,
    role text,
    department text,
    location text,
    manager_name text,
    start_date date,
    created_at timestamp without time zone DEFAULT now(),
    salesforce_id text
);
CREATE TABLE public.provisioning_runs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    employee_id uuid,
    status text DEFAULT 'pending'::text,
    started_at timestamp without time zone DEFAULT now(),
    completed_at timestamp without time zone
);
CREATE TABLE public.task_artifacts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    task_id uuid,
    key text,
    value jsonb
);
CREATE TABLE public.tasks (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    run_id uuid,
    app_id uuid,
    name text,
    status text DEFAULT 'pending'::text,
    attempt_count integer DEFAULT 0,
    started_at timestamp without time zone,
    ended_at timestamp without time zone,
    blocked_reason text
);
ALTER TABLE ONLY public.app_dependencies
    ADD CONSTRAINT app_dependencies_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.apps
    ADD CONSTRAINT apps_key_key UNIQUE (key);
ALTER TABLE ONLY public.apps
    ADD CONSTRAINT apps_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.employees
    ADD CONSTRAINT employees_pkey PRIMARY KEY (id);
ALTER TABLE public.employees
    ADD CONSTRAINT employees_salesforce_id_key UNIQUE (salesforce_id);
ALTER TABLE ONLY public.provisioning_runs
    ADD CONSTRAINT provisioning_runs_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.task_artifacts
    ADD CONSTRAINT task_artifacts_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT tasks_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.app_dependencies
    ADD CONSTRAINT app_dependencies_app_id_fkey FOREIGN KEY (app_id) REFERENCES public.apps(id);
ALTER TABLE ONLY public.app_dependencies
    ADD CONSTRAINT app_dependencies_depends_on_app_id_fkey FOREIGN KEY (depends_on_app_id) REFERENCES public.apps(id);
ALTER TABLE ONLY public.provisioning_runs
    ADD CONSTRAINT provisioning_runs_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES public.employees(id);
ALTER TABLE ONLY public.task_artifacts
    ADD CONSTRAINT task_artifacts_task_id_fkey FOREIGN KEY (task_id) REFERENCES public.tasks(id);
ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT tasks_app_id_fkey FOREIGN KEY (app_id) REFERENCES public.apps(id);
ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT tasks_run_id_fkey FOREIGN KEY (run_id) REFERENCES public.provisioning_runs(id);
