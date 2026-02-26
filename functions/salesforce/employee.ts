import type { Request, Response } from 'express'

type Payload = {
  Id?: string
  id?: string
  FirstName?: string
  LastName?: string
  Email?: string
  Title?: string
  Department?: string
  Location?: string
  Location__c?: string
  ManagerName?: string
  Manager__c?: string
  StartDate?: string
  StartDate__c?: string
  LastModifiedDate?: string
  [key: string]: any
}

function mustEnv(name: string): string {
  const v = process.env[name]
  if (!v) throw new Error(`Missing env var: ${name}`)
  return v
}

export default async function handler(req: Request, res: Response) {
  try {
    if (req.method !== 'POST') return res.status(405).json({ error: 'Method Not Allowed' })

    // 1) Verify shared secret from Salesforce
    const expected = mustEnv('NHOST_WEBHOOK_SECRET')
    const received = req.header('x-webhook-secret')
    if (!received || received !== expected) {
      return res.status(401).json({ error: 'Unauthorized' })
    }

    const body = (req.body ?? {}) as Payload
    const salesforceId = body.Id || body.id
    if (!salesforceId) return res.status(400).json({ error: 'Missing Salesforce Id (Id)' })

    // 2) Map fields into employees table
    const employee = {
      salesforce_id: salesforceId,
      first_name: body.FirstName ?? null,
      last_name: body.LastName ?? null,
      personal_email: body.Email ?? null,
      role: body.Title ?? null,
      department: body.Department ?? null,
      location: body.Location__c ?? body.Location ?? null,
      manager_name: body.Manager__c ?? body.ManagerName ?? null,
      start_date: (body.StartDate__c ?? body.StartDate ?? null) as string | null
    }

    // 3) Upsert into Postgres via Hasura GraphQL
    // For local dev: set NHOST_HASURA_GRAPHQL_URL to https://local.graphql.local.nhost.run/v1/graphql
    const hasuraUrl = mustEnv('NHOST_GRAPHQL_URL')
    const adminSecret = mustEnv('HASURA_GRAPHQL_ADMIN_SECRET')

    const mutation = `
      mutation UpsertEmployee($object: employees_insert_input!) {
        insert_employees_one(
          object: $object,
          on_conflict: {
            constraint: employees_salesforce_id_key,
            update_columns: [
              first_name,
              last_name,
              personal_email,
              role,
              department,
              location,
              manager_name,
              start_date
            ]
          }
        ) {
          id
          salesforce_id
          first_name
          last_name
        }
      }
    `

    const r = await fetch(hasuraUrl, {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        'x-hasura-admin-secret': adminSecret
      },
      body: JSON.stringify({ query: mutation, variables: { object: employee } })
    })

    const json = await r.json()
    if (!r.ok || json.errors) {
      return res.status(500).json({ error: 'Hasura error', details: json.errors ?? json })
    }

    return res.json({ ok: true, employee: json.data.insert_employees_one })
  } catch (e: any) {
    return res.status(500).json({ error: e?.message ?? 'Unknown error' })
  }
}