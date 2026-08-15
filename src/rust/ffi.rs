use crate::addon_client::AddonClient;
use crate::quad_manager::QuadManager;
use std::ffi::{CStr, CString};
use std::os::raw::c_char;
use tokio::runtime::Runtime;

pub struct CoreHandle {
    pub manager: QuadManager,
    pub client: AddonClient,
    pub runtime: Runtime,
}

#[no_mangle]
pub extern "C" fn stremio_quad_create() -> *mut CoreHandle {
    let runtime = match Runtime::new() {
        Ok(rt) => rt,
        Err(_) => return std::ptr::null_mut(),
    };
    let handle = Box::new(CoreHandle {
        manager: QuadManager::new(),
        client: AddonClient::new(),
        runtime,
    });
    Box::into_raw(handle)
}

#[no_mangle]
pub extern "C" fn stremio_quad_destroy(handle: *mut CoreHandle) {
    if !handle.is_null() {
        unsafe {
            drop(Box::from_raw(handle));
        }
    }
}

#[no_mangle]
pub extern "C" fn stremio_quad_get_state(handle: *mut CoreHandle) -> *mut c_char {
    if handle.is_null() {
        return std::ptr::null_mut();
    }
    let handle = unsafe { &*handle };
    let state = handle.manager.get_state();
    let json = serde_json::to_string(&state).unwrap_or_else(|_| "{}".to_string());
    CString::new(json).map(|c| c.into_raw()).unwrap_or(std::ptr::null_mut())
}

#[no_mangle]
pub extern "C" fn stremio_quad_set_slot_stream(
    handle: *mut CoreHandle,
    slot_idx: usize,
    stream_url: *const c_char,
    title: *const c_char,
    poster: *const c_char,
) {
    if handle.is_null() {
        return;
    }
    let handle = unsafe { &mut *handle };
    let s_url = if stream_url.is_null() {
        ""
    } else {
        unsafe { CStr::from_ptr(stream_url) }.to_str().unwrap_or("")
    };
    let s_title = if title.is_null() {
        ""
    } else {
        unsafe { CStr::from_ptr(title) }.to_str().unwrap_or("")
    };
    let s_poster = if poster.is_null() {
        ""
    } else {
        unsafe { CStr::from_ptr(poster) }.to_str().unwrap_or("")
    };

    handle.manager.set_slot_stream(slot_idx, s_url, s_title, s_poster);
}

#[no_mangle]
pub extern "C" fn stremio_quad_set_active_audio(handle: *mut CoreHandle, slot_idx: usize) {
    if handle.is_null() {
        return;
    }
    let handle = unsafe { &mut *handle };
    handle.manager.set_active_audio_slot(slot_idx);
}

#[no_mangle]
pub extern "C" fn stremio_quad_set_solo(handle: *mut CoreHandle, slot_idx: isize) {
    if handle.is_null() {
        return;
    }
    let handle = unsafe { &mut *handle };
    let solo = if slot_idx < 0 { None } else { Some(slot_idx as usize) };
    handle.manager.set_solo_slot(solo);
}

#[no_mangle]
pub extern "C" fn stremio_quad_fetch_catalog(
    handle: *mut CoreHandle,
    addon_url: *const c_char,
    catalog_type: *const c_char,
    catalog_id: *const c_char,
    search_query: *const c_char,
) -> *mut c_char {
    if handle.is_null() || addon_url.is_null() {
        return std::ptr::null_mut();
    }
    let handle = unsafe { &*handle };
    let addon_str = match unsafe { CStr::from_ptr(addon_url) }.to_str() {
        Ok(s) => s,
        Err(_) => return std::ptr::null_mut(),
    };
    let type_str = if catalog_type.is_null() {
        "movie"
    } else {
        unsafe { CStr::from_ptr(catalog_type) }.to_str().unwrap_or("movie")
    };
    let id_str = if catalog_id.is_null() {
        "top"
    } else {
        unsafe { CStr::from_ptr(catalog_id) }.to_str().unwrap_or("top")
    };
    let query_str = if search_query.is_null() {
        None
    } else {
        match unsafe { CStr::from_ptr(search_query) }.to_str() {
            Ok(s) => if s.trim().is_empty() { None } else { Some(s) },
            Err(_) => None,
        }
    };

    let res = handle.runtime.block_on(handle.client.fetch_catalog(
        addon_str,
        type_str,
        id_str,
        query_str,
    ));

    let json = match res {
        Ok(cat) => serde_json::to_string(&cat).unwrap_or_else(|_| "{\"metas\":[]}".to_string()),
        Err(err) => serde_json::json!({ "error": err, "metas": [] }).to_string(),
    };

    CString::new(json).map(|c| c.into_raw()).unwrap_or(std::ptr::null_mut())
}

#[no_mangle]
pub extern "C" fn stremio_quad_search(
    handle: *mut CoreHandle,
    query: *const c_char,
    item_type: *const c_char,
) -> *mut c_char {
    if handle.is_null() || query.is_null() || item_type.is_null() {
        return std::ptr::null_mut();
    }
    let handle = unsafe { &*handle };
    let query_str = match unsafe { CStr::from_ptr(query) }.to_str() {
        Ok(s) => s,
        Err(_) => return std::ptr::null_mut(),
    };
    let type_str = match unsafe { CStr::from_ptr(item_type) }.to_str() {
        Ok(s) => s,
        Err(_) => return std::ptr::null_mut(),
    };

    let res = handle
        .runtime
        .block_on(handle.client.search(query_str, type_str));

    let json = match res {
        Ok(cat) => serde_json::to_string(&cat).unwrap_or_else(|_| "{\"metas\":[]}".to_string()),
        Err(err) => serde_json::json!({ "error": err, "metas": [] }).to_string(),
    };

    CString::new(json).map(|c| c.into_raw()).unwrap_or(std::ptr::null_mut())
}

#[no_mangle]
pub extern "C" fn stremio_quad_resolve_streams(
    handle: *mut CoreHandle,
    addon_url: *const c_char,
    item_type: *const c_char,
    id: *const c_char,
) -> *mut c_char {
    if handle.is_null() || addon_url.is_null() || item_type.is_null() || id.is_null() {
        return std::ptr::null_mut();
    }
    let handle = unsafe { &*handle };
    let addon_str = match unsafe { CStr::from_ptr(addon_url) }.to_str() {
        Ok(s) => s,
        Err(_) => return std::ptr::null_mut(),
    };
    let type_str = match unsafe { CStr::from_ptr(item_type) }.to_str() {
        Ok(s) => s,
        Err(_) => return std::ptr::null_mut(),
    };
    let id_str = match unsafe { CStr::from_ptr(id) }.to_str() {
        Ok(s) => s,
        Err(_) => return std::ptr::null_mut(),
    };

    let res = handle
        .runtime
        .block_on(handle.client.resolve_streams(addon_str, type_str, id_str));

    let json = match res {
        Ok(streams) => serde_json::to_string(&streams).unwrap_or_else(|_| "{\"streams\":[]}".to_string()),
        Err(err) => serde_json::json!({ "error": err, "streams": [] }).to_string(),
    };

    CString::new(json).map(|c| c.into_raw()).unwrap_or(std::ptr::null_mut())
}

#[no_mangle]
pub extern "C" fn stremio_quad_free_string(s: *mut c_char) {
    if !s.is_null() {
        unsafe {
            drop(CString::from_raw(s));
        }
    }
}
