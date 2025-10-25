export async function GET() {
  const appUrl = process.env.NEXT_PUBLIC_URL || 'https://wecolor.vercel.app';

  const manifest = {
    accountAssociation: {
      header: "eyJmaWQiOjI5NDY4OCwidHlwZSI6ImF1dGgiLCJrZXkiOiIweGI0RjFERERCYTE1QThjYTNBQzAwNTQxNzZjMEMxZTI2REJlRTU3NDEifQ",
      payload: "eyJkb21haW4iOiJ3ZWNvbG9yLnZlcmNlbC5hcHAifQ",
      signature: "RuvSgJ3pdbFhXp5KKzGWkBqHYPngPx3klV8T0Pu2M0cTARpT5"
    },
    baseBuilder: {
      address: process.env.NEXT_PUBLIC_BASE_BUILDER_ADDRESS || ""
    },
    miniapp: {
      version: "1",
      name: "WeColor",
      url: appUrl,
      iconUrl: `${appUrl}/icon`,
      iconUrlSecondary: `${appUrl}/icon-secondary`,
      splashImageUrl: `${appUrl}/splash`,
      splashBackgroundColor: "#0052FF",
      homeUrl: appUrl,
      description: "Express your daily mood through color. Contribute to collective NFTs and earn rewards.",
      shortDescription: "Daily collective color NFTs",
      categories: ["art", "social", "nft"],
      primaryCategory: "art",
      tags: ["nft", "art", "collectible", "base", "onchain"]
    }
  };

  return Response.json(manifest);
}
