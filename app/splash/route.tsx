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
          backgroundColor: '#0052FF',
          backgroundImage: 'linear-gradient(135deg, #0052FF 0%, #2D6CFF 100%)',
        }}
      >
        <div style={{ fontSize: 300, marginBottom: 60 }}>🎨</div>
        <div
          style={{
            fontSize: 100,
            fontWeight: 'bold',
            color: 'white',
          }}
        >
          WeColor
        </div>
        <div
          style={{
            fontSize: 40,
            color: 'rgba(255,255,255,0.8)',
            marginTop: 20,
          }}
        >
          Daily Collective Color NFT
        </div>
      </div>
    ),
    {
      width: 1080,
      height: 1920,
    }
  );
}
