import { ImageResponse } from 'next/og';

export const runtime = 'edge';

export async function GET() {
  return new ImageResponse(
    (
      <div
        style={{
          height: '100%',
          width: '100%',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          backgroundColor: '#0F172A',
          backgroundImage: 'linear-gradient(135deg, #0052FF 0%, #2D6CFF 100%)',
        }}
      >
        <div
          style={{
            display: 'flex',
            fontSize: 120,
            fontWeight: 'bold',
            color: 'white',
            marginBottom: 40,
          }}
        >
          🎨 WeColor
        </div>
        <div
          style={{
            display: 'flex',
            fontSize: 40,
            color: 'rgba(255,255,255,0.9)',
            textAlign: 'center',
          }}
        >
          Daily Collective Color NFT on Base
        </div>
      </div>
    ),
    {
      width: 1200,
      height: 630,
    }
  );
}
