import type { NextConfig } from "next";

// For Tauri builds: TAURI_BUILD=1 bun run build:static
// For browser dev:  bun run dev  (no env var)
const isTauriBuild = process.env.TAURI_BUILD === "1";

const nextConfig: NextConfig = {
  // Tauri needs a static export. For browser dev, we use the default (no output)
  // so HMR and dev server work normally.
  output: isTauriBuild ? "export" : "standalone",
  // For static export, we need to disable image optimization (no server-side processing)
  images: isTauriBuild ? { unoptimized: true } : undefined,
  // For static export, trailing slash makes paths work as file:// URLs
  trailingSlash: isTauriBuild,
  typescript: {
    ignoreBuildErrors: true,
  },
  reactStrictMode: false,
};

export default nextConfig;
