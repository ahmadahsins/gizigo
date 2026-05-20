import * as fs from 'fs';
import * as path from 'path';
import * as admin from 'firebase-admin';
import { geohashForLocation } from 'geofire-common';
import { SEED_FOODS, SEED_MERCHANTS } from './seed-data';

function loadEnvFile(): void {
  const envPath = path.resolve(__dirname, '../.env');
  if (!fs.existsSync(envPath)) return;

  for (const rawLine of fs.readFileSync(envPath, 'utf8').split('\n')) {
    const line = rawLine.trim();
    if (!line || line.startsWith('#')) continue;

    const separatorIndex = line.indexOf('=');
    if (separatorIndex === -1) continue;

    const key = line.slice(0, separatorIndex).trim();
    let value = line.slice(separatorIndex + 1).trim();
    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1);
    }

    if (process.env[key] === undefined) {
      process.env[key] = value;
    }
  }
}

function initFirebase(): admin.firestore.Firestore {
  loadEnvFile();

  const projectId = process.env.FIREBASE_PROJECT_ID;
  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
  const privateKey = process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n');

  if (!projectId || !clientEmail || !privateKey) {
    throw new Error(
      'Missing Firebase credentials. Set FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, and FIREBASE_PRIVATE_KEY in backend/.env',
    );
  }

  if (!admin.apps.length) {
    admin.initializeApp({
      credential: admin.credential.cert({ projectId, clientEmail, privateKey }),
    });
  }

  return admin.firestore();
}

async function seedMerchants(db: admin.firestore.Firestore): Promise<void> {
  const batch = db.batch();
  const now = admin.firestore.FieldValue.serverTimestamp();

  for (const merchant of SEED_MERCHANTS) {
    const { id, coordinates, ...rest } = merchant;
    const ref = db.collection('merchants').doc(id);
    batch.set(
      ref,
      {
        ...rest,
        coordinates: new admin.firestore.GeoPoint(
          coordinates.latitude,
          coordinates.longitude,
        ),
        geohash: geohashForLocation([
          coordinates.latitude,
          coordinates.longitude,
        ]),
        created_at: now,
        updated_at: now,
      },
      { merge: true },
    );
  }

  await batch.commit();
  console.log(`Seeded ${SEED_MERCHANTS.length} merchants.`);
}

async function seedFoods(db: admin.firestore.Firestore): Promise<void> {
  const batch = db.batch();
  const now = admin.firestore.FieldValue.serverTimestamp();

  for (const food of SEED_FOODS) {
    const { id, ...rest } = food;
    const ref = db.collection('foods').doc(id);
    batch.set(
      ref,
      {
        food_id: id,
        ...rest,
        created_at: now,
        updated_at: now,
      },
      { merge: true },
    );
  }

  await batch.commit();
  console.log(`Seeded ${SEED_FOODS.length} foods.`);
}

async function main(): Promise<void> {
  const db = initFirebase();
  await seedMerchants(db);
  await seedFoods(db);
  console.log('Seed complete.');
}

main().catch((error: unknown) => {
  console.error('Seed failed:', error);
  process.exit(1);
});
