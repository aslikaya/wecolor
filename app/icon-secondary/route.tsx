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
          background: 'linear-gradient(135deg, #7C3AED 0%, #EC4899 100%)',
        }}
      >
        <div style={{ fontSize: 280 }}>🌈</div>
      </div>
    ),
    {
      width: 512,
      height: 512,
    }
  );
}
