export async function GET() {
  const appUrl = process.env.NEXT_PUBLIC_URL || 'https://wecolor.vercel.app';

  const manifest = {
    accountAssociation: {
      header: process.env.NEXT_PUBLIC_ACCOUNT_ASSOCIATION_HEADER,
      payload: process.env.NEXT_PUBLIC_ACCOUNT_ASSOCIATION_PAYLOAD,
      signature: process.env.NEXT_PUBLIC_ACCOUNT_ASSOCIATION_SIGNATURE
    },
    baseBuilder: {
      address: process.env.NEXT_PUBLIC_BASE_BUILDER_ADDRESS || ""
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
