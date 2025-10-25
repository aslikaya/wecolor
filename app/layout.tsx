import type { Metadata } from "next";
import { Inter, Source_Code_Pro } from "next/font/google";
import { RootProvider } from "./rootProvider";
import "./globals.css";

const inter = Inter({
  variable: "--font-inter",
  subsets: ["latin"],
});

const sourceCodePro = Source_Code_Pro({
  variable: "--font-source-code-pro",
  subsets: ["latin"],
});

const appUrl = process.env.NEXT_PUBLIC_URL || 'https://wecolor.vercel.app';

export const metadata: Metadata = {
  title: "WeColor - Daily Collective Color NFT",
  description: "Express your daily mood through color. Contribute to collective NFTs and earn rewards on Base.",
  openGraph: {
    title: "WeColor - Daily Collective Color NFT",
    description: "Express your daily mood through color. Contribute to collective NFTs and earn rewards on Base.",
    images: [`${appUrl}/og-image`],
  },
  other: {
    'fc:miniapp': JSON.stringify({
      version: 'next',
      imageUrl: `${appUrl}/og-image`,
      button: {
        title: 'Select Your Color',
        action: {
          type: 'launch',
          name: 'WeColor',
          url: appUrl,
          splashImageUrl: `${appUrl}/splash`,
          splashBackgroundColor: '#0052FF'
        }
      }
    })
  }
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className={`${inter.variable} ${sourceCodePro.variable}`}>
        <RootProvider>{children}</RootProvider>
      </body>
    </html>
  );
}
