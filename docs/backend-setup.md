# Backend Configuration for Mobile App

This document outlines the required backend configuration for the SmarterNEET mobile application to work properly with the Next.js API hosted on Vercel.

## CORS Configuration

### Next.js API Route (App Router)

For your `/api/subjects` endpoint, ensure proper CORS headers are set:

```typescript
// app/api/subjects/route.ts
export async function GET(request: Request) {
  try {
    // Your API logic here
    const subjects = await getSubjects();
    
    return new Response(JSON.stringify({ 
      data: subjects,
      source: 'api',
      timestamp: new Date().toISOString()
    }), {
      status: 200,
      headers: {
        // CORS headers for mobile app
        'Access-Control-Allow-Origin': '*', // Replace with specific domain for production
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Client-ID, x-vercel-protection-bypass',
        'Access-Control-Max-Age': '86400', // 24 hours
        
        // Content headers
        'Content-Type': 'application/json',
        'Cache-Control': 'public, max-age=300', // 5 minutes cache
        
        // Security headers
        'X-Content-Type-Options': 'nosniff',
        'X-Frame-Options': 'DENY',
      },
    });
  } catch (error) {
    return new Response(JSON.stringify({ 
      error: 'Internal server error',
      message: error.message 
    }), {
      status: 500,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Content-Type': 'application/json',
      },
    });
  }
}

// Handle preflight requests
export async function OPTIONS(request: Request) {
  return new Response(null, {
    status: 200,
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Client-ID, x-vercel-protection-bypass',
      'Access-Control-Max-Age': '86400',
    },
  });
}
```

### Pages API Route (Alternative)

If using Pages Router:

```typescript
// pages/api/subjects.ts
import type { NextApiRequest, NextApiResponse } from 'next';

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse
) {
  // Set CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Client-ID, x-vercel-protection-bypass');
  
  // Handle preflight
  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }
  
  if (req.method === 'GET') {
    try {
      const subjects = await getSubjects();
      
      res.status(200).json({
        data: subjects,
        source: 'api',
        timestamp: new Date().toISOString()
      });
    } catch (error) {
      res.status(500).json({
        error: 'Internal server error',
        message: error.message
      });
    }
  } else {
    res.setHeader('Allow', ['GET']);
    res.status(405).json({ error: `Method ${req.method} Not Allowed` });
  }
}
```

## Vercel Configuration

### 1. Protection Bypass for Automation

In your Vercel project settings:

1. Go to **Settings** → **Functions**
2. Find **Protection Bypass for Automation**
3. Generate a bypass secret
4. Update the Flutter app's `lib/config.dart`:
   ```dart
   static const String? vercelBypassSecret = 'your-generated-secret';
   ```

### 2. Environment Variables

Set these in your Vercel project:

```bash
# .env.local or Vercel Environment Variables
CORS_ORIGIN=*  # Replace with specific domains in production
API_BASE_URL=https://dev.smarterneet.com
VERCEL_BYPASS_SECRET=your-generated-secret
```

### 3. Custom Headers (vercel.json)

Create a `vercel.json` file in your project root:

```json
{
  "headers": [
    {
      "source": "/api/(.*)",
      "headers": [
        {
          "key": "Access-Control-Allow-Origin",
          "value": "*"
        },
        {
          "key": "Access-Control-Allow-Methods", 
          "value": "GET, POST, PUT, DELETE, OPTIONS"
        },
        {
          "key": "Access-Control-Allow-Headers",
          "value": "Content-Type, Authorization, X-Client-ID, x-vercel-protection-bypass"
        }
      ]
    }
  ]
}
```

## Security Considerations

### Production CORS Settings

For production, replace `*` with specific origins:

```typescript
const allowedOrigins = [
  'https://yourapp.com',
  'https://www.yourapp.com',
  // Mobile app bundle identifiers if needed
];

const origin = request.headers.get('origin');
const corsOrigin = allowedOrigins.includes(origin) ? origin : 'null';

// Use corsOrigin instead of '*'
'Access-Control-Allow-Origin': corsOrigin
```

### Rate Limiting

Implement rate limiting for mobile requests:

```typescript
import { Ratelimit } from '@upstash/ratelimit';
import { Redis } from '@upstash/redis';

const ratelimit = new Ratelimit({
  redis: Redis.fromEnv(),
  limiter: Ratelimit.slidingWindow(100, '1 h'), // 100 requests per hour
});

export async function GET(request: Request) {
  const clientId = request.headers.get('X-Client-ID');
  
  if (clientId) {
    const { success } = await ratelimit.limit(clientId);
    if (!success) {
      return new Response(JSON.stringify({ error: 'Rate limit exceeded' }), {
        status: 429,
        headers: { 'Content-Type': 'application/json' }
      });
    }
  }
  
  // Continue with normal logic...
}
```

## Testing the Configuration

### Test CORS with curl

```bash
# Test preflight request
curl -X OPTIONS -H "Origin: http://localhost" \
     -H "Access-Control-Request-Method: GET" \
     -H "Access-Control-Request-Headers: Content-Type" \
     https://dev.smarterneet.com/api/subjects

# Test actual request
curl -X GET -H "Origin: http://localhost" \
     -H "Content-Type: application/json" \
     -H "X-Client-ID: test-client" \
     https://dev.smarterneet.com/api/subjects
```

### Test with Mobile App Debug Tool

The Flutter app includes a debug button (🐛) when `enableApiLogging` is true in `config.dart`. This runs comprehensive network diagnostics.

## Common Issues

1. **CORS Errors**: Ensure all required headers are included in both GET and OPTIONS responses
2. **Security Checkpoint**: Configure Vercel Protection Bypass as described above
3. **SSL Issues**: Ensure all endpoints use HTTPS
4. **Mobile-Specific Headers**: Include `X-Requested-With` and other mobile-friendly headers

## Monitoring

Consider adding logging to track mobile app requests:

```typescript
export async function GET(request: Request) {
  const userAgent = request.headers.get('user-agent');
  const clientId = request.headers.get('x-client-id');
  
  console.log('Mobile API request:', {
    userAgent,
    clientId,
    timestamp: new Date().toISOString(),
    url: request.url
  });
  
  // Continue with normal logic...
}
```