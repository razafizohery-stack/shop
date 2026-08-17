import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { S3Client, PutObjectCommand } from "npm:@aws-sdk/client-s3@3.629.0"
import { getSignedUrl } from "npm:@aws-sdk/s3-request-presigner@3.629.0"

serve(async (req) => {
  const { fileName, contentType } = await req.json()

  const s3Client = new S3Client({
    region: "auto",
    endpoint: Deno.env.get("R2_ENDPOINT"),
    credentials: {
      accessKeyId: Deno.env.get("R2_ACCESS_KEY")!,
      secretAccessKey: Deno.env.get("R2_SECRET_KEY")!,
    },
  })

  const command = new PutObjectCommand({
    Bucket: Deno.env.get("R2_BUCKET_NAME"),
    Key: fileName,
    ContentType: contentType,
  })

  // Générer une URL valide pendant 60 secondes
  const signedUrl = await getSignedUrl(s3Client, command, { expiresIn: 60 })

  return new Response(JSON.stringify({ url: signedUrl }), {
    headers: { "Content-Type": "application/json" },
  })
})
