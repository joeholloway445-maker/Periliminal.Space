import { NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'
import { cookies } from 'next/headers'

export async function GET() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return NextResponse.json({ error: 'unauthorized' }, { status: 401 })

  const cookieStore = await cookies()
  const characterId = cookieStore.get('selected_character_id')?.value
  if (!characterId) return NextResponse.json({ error: 'no character selected' }, { status: 404 })

  const { data: character, error } = await supabase
    .from('characters')
    .select('id, faction, race, frame, physical_mod, prestige_level, xp')
    .eq('id', characterId)
    .eq('user_id', user.id)
    .single()

  if (error || !character) {
    return NextResponse.json({ error: 'character not found' }, { status: 404 })
  }

  return NextResponse.json(character)
}
