export async function GET() {
  const appUrl = process.env.NEXT_PUBLIC_URL || 'https://wecolor.vercel.app';

  const manifest = {
    accountAssociation: {
      header: "TO_BE_FILLED", // Will be filled after account association
      payload: "TO_BE_FILLED",
      signature: "TO_BE_FILLED"
    },
    baseBuilder: {
      address: process.env.NEXT_PUBLIC_BASE_BUILDER_ADDRESS || "TO_BE_FILLED"
    },
    miniapp: {
      name: "WeColor",
      url: appUrl,
      iconUrl: `${appUrl}/icon.png`,
      iconUrlSecondary: `${appUrl}/icon-secondary.png`,
      splashImageUrl: `${appUrl}/splash.png`,
      splashBackgroundColor: "#0052FF",
      homeUrl: appUrl,
      description: "Express your daily mood through color. Contribute to collective NFTs and earn rewards on Base.",
      shortDescription: "Daily collective color NFTs on Base",
      categories: ["art", "social", "nft"],
      tags: ["nft", "art", "collectible", "base", "onchain"]
    }
  };

  return Response.json(manifest);
}
