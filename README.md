# Fasthabiqul Khairath — Melaad Fest 2026 Website

A responsive competition website for **Thalameez Sayyid Marhoom Ramanthali — Melaad Fest 2026**, campaign name **Fasthabiqul Khairath**.

## Included pages

- Home — live Senior, Junior and Overall team scores + individual Overall Champions leaderboard
- Competitions — programme-wise team points
- Individual Marks — participant programme marks
- Gallery — photos/videos with visitor download option
- About and Contact/Feedback, including private user-submitted feedback
- Admin — email/password login, score entry, visitor analytics and gallery management
- Visitor gate — first-time visitors enter name and place before viewing the website

## Supabase setup

1. Open your Supabase project and go to **SQL Editor**.
2. Open `supabase-schema.sql`, replace `YOUR-ADMIN-EMAIL@example.com` with the administrator email, and run the SQL.
3. Confirm `config.js` contains your project URL and public anon/publishable key. Never put a service-role key in this website.
4. Enable **Email** authentication and create the admin user with the same email added in the SQL.
5. Add the deployed Admin page URL (for example, `https://your-site.example/admin.html`) to Supabase Auth's allowed redirect URLs if needed by your project.
6. Enable Realtime for `scores` and `team_scores` in the Supabase project.
7. Deploy the entire folder to a static website host.

The schema creates the score, visitor analytics, and gallery tables and the public `gallery` storage bucket. Row-level security allows visitors to read scores and gallery items, while only the approved admin can change scores or manage gallery media.

## Publish with GitHub Pages

1. Create a **public** GitHub repository named `by-SMKT` under the `TSMR` account.
2. Upload the contents of this website folder to the repository root. Include the `.github/workflows/pages.yml` workflow and `.nojekyll` file.
3. In the repository, open **Settings → Pages** and set the build and deployment source to **GitHub Actions**.
4. Push to the `main` branch, or manually run **Deploy static website to GitHub Pages** from the **Actions** tab.
5. Once the deployment succeeds, the site will be available at `https://tsmr.github.io/by-SMKT/`.
6. Add `https://tsmr.github.io/by-SMKT/**` to Supabase Auth's allowed redirect URLs.

The GitHub Pages workflow deploys the repository root whenever a commit is pushed to `main`. Do not add a Supabase service-role key to the repository; the website should use only the public anon/publishable key.

Feedback sent from Contact/Feedback is readable only by approved admins. If the original schema was already run in this project, run this migration in SQL Editor to add private feedback storage:

```sql
create table if not exists public.feedback (
  id uuid primary key default gen_random_uuid(),
  name text check (name is null or char_length(name) <= 80),
  message text not null check (char_length(btrim(message)) between 1 and 2000),
  created_at timestamptz not null default now()
);

alter table public.feedback enable row level security;

drop policy if exists "public can submit feedback" on public.feedback;
create policy "public can submit feedback"
on public.feedback for insert
to anon, authenticated
with check (
  char_length(btrim(message)) between 1 and 2000
  and (name is null or char_length(name) <= 80)
);

drop policy if exists "admin can read feedback" on public.feedback;
create policy "admin can read feedback"
on public.feedback for select
to authenticated
using (public.is_admin());

grant insert on public.feedback to anon, authenticated;
grant select on public.feedback to authenticated;
```

The Admin Panel displays submitted messages in its **User Feedback** section.

## Scoring design

- **Individual participant** marks contribute to participant and team totals.
- **Team / group programme** scores are added once to the selected team.
- Competition totals combine individual and team/group marks. The Overall Champions leaderboard ranks individual marks only.

## Files

- `index.html`, `competitions.html`, `individual-marks.html`, `gallery.html`, `about.html`, `contact.html` — public pages
- `admin.html` — Admin Panel
- `styles.css` — responsive design
- `data.js` — teams, participants and programmes
- `app.js` — public site logic and Supabase data loading
- `admin.js` — admin login, marks, analytics and media management
- `config.js` — Supabase connection settings
- `supabase-schema.sql` — tables, access policies and gallery storage setup

## Contact details included

- Sayyid Hamid Koayamma Thangal Al Jalali Al Bukhari — +91 98460 20519
- Mudarris / Professor: Aslam Falahi Iyyankode — +91 85899 39295
- Public queries / WhatsApp — +91 99466 06469
