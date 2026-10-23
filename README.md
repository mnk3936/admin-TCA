# Zahran Calendar

Instagram content calendar built with [Astro](https://astro.build) and [Supabase](https://supabase.com).

## Project Structure

```text
├── src/
│   ├── layouts/
│   │   └── Layout.astro         # Common layout, DM Sans font, global CSS
│   ├── pages/
│   │   ├── index.astro          # Public client calendar
│   │   └── admin/
│   │       └── index.astro      # Admin portal for managing clients and posts
│   ├── lib/
│   │   ├── config.ts            # Supabase config (with env var overrides)
│   │   └── supabase.ts          # Typed Supabase client instance
│   └── styles/
│       └── style.css            # Calendar styling and dark/light mode themes
├── astro.config.mjs
├── package.json
└── tsconfig.json
```

## Getting Started

### 1. Install dependencies

```bash
npm install
```

### 2. Start local development server

```bash
npm run dev
```

### 3. Build for production

```bash
npm run build
```

### 4. Preview production build

```bash
npm run preview
```

## Environment Variables (Optional)

You can customize the Supabase connection by setting:
- `PUBLIC_SUPABASE_URL`
- `PUBLIC_SUPABASE_ANON_KEY`
