import { ImageResponse } from 'next/og';

export const runtime = 'edge';

export async function GET() {
  return new ImageResponse(
    (
      <div
        style={{
          width: '100%',
          height: '100%',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          background: 'linear-gradient(135deg, #0052FF 0%, #2D6CFF 100%)',
        }}
      >
        <div style={{ fontSize: 280 }}>🎨</div>
      </div>
    ),
    {
      width: 512,
      height: 512,
    }
  );
}
