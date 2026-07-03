import { createClient } from '@supabase/supabase-js'

const supabaseUrl = 'https://kjlfrqogkjubudrmvfqx.supabase.co'

const supabaseKey = 'sb_publishable_fy5qQUvoBXpycDCJztv4Rw_X-0sLBDH'

export const supabase = createClient(
  supabaseUrl,
  supabaseKey
)