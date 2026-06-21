import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";
import { Toaster } from "@/components/ui/toaster";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "Unemployment Simulator",
  description: "Make $1,000,000 without getting a job. Hustle your way through 8 shady schemes — e-com, trading, gambling, drugs, scamming, robbery, tax fraud, and wire fraud. Just don't end up at McDonald's.",
  keywords: ["unemployment simulator", "hustle game", "idle game", "satire game", "browser game"],
  authors: [{ name: "Unemployment Simulator" }],
  icons: {
    icon: "https://z-cdn.chatglm.cn/z-ai/static/logo.svg",
  },
  openGraph: {
    title: "Unemployment Simulator",
    description: "Make $1M without getting a job. Avoid McDonald's at all costs.",
    url: "https://chat.z.ai",
    siteName: "Unemployment Simulator",
    type: "website",
  },
  twitter: {
    card: "summary_large_image",
    title: "Unemployment Simulator",
    description: "Make $1M without getting a job. Avoid McDonald's at all costs.",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body
        className={`${geistSans.variable} ${geistMono.variable} antialiased bg-background text-foreground`}
      >
        {children}
        <Toaster />
      </body>
    </html>
  );
}
