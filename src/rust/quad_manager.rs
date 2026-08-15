use crate::models::{QuadState, SlotState};

pub struct QuadManager {
    pub slots: [SlotState; 4],
    pub active_audio_slot: usize,
    pub solo_slot: Option<usize>,
}

impl QuadManager {
    pub fn new() -> Self {
        let mut slots = [
            SlotState::default(),
            SlotState::default(),
            SlotState::default(),
            SlotState::default(),
        ];
        for (i, slot) in slots.iter_mut().enumerate() {
            slot.index = i;
            slot.is_muted = i != 0;
            slot.volume = 1.0;
        }

        Self {
            slots,
            active_audio_slot: 0,
            solo_slot: None,
        }
    }

    pub fn set_slot_stream(
        &mut self,
        slot_idx: usize,
        stream_url: &str,
        title: &str,
        poster: &str,
    ) {
        if slot_idx < 4 {
            let slot = &mut self.slots[slot_idx];
            slot.stream_url = stream_url.to_string();
            slot.title = title.to_string();
            slot.poster = poster.to_string();
            slot.is_playing = !stream_url.is_empty();
        }
    }

    pub fn set_active_audio_slot(&mut self, slot_idx: usize) {
        if slot_idx < 4 {
            self.active_audio_slot = slot_idx;
            for (i, slot) in self.slots.iter_mut().enumerate() {
                slot.is_muted = i != slot_idx;
            }
        }
    }

    pub fn set_solo_slot(&mut self, slot_idx: Option<usize>) {
        self.solo_slot = slot_idx;
    }

    pub fn get_state(&self) -> QuadState {
        QuadState {
            slots: self.slots.clone(),
            active_audio_slot: self.active_audio_slot,
            solo_slot: self.solo_slot,
        }
    }
}
