use crate::models::{CatalogResponse, Manifest, MetaResponse, StreamResponse};
use reqwest::Client;
use std::time::Duration;

#[derive(Clone)]
pub struct AddonClient {
    client: Client,
    pub cinemeta_url: String,
}

impl AddonClient {
    pub fn new() -> Self {
        let client = Client::builder()
            .timeout(Duration::from_secs(12))
            .danger_accept_invalid_certs(true)
            .build()
            .unwrap_or_else(|_| Client::new());

        Self {
            client,
            cinemeta_url: "https://v3-cinemeta.strem.io".to_string(),
        }
    }

    /// Fetch addon manifest to discover its catalogs and capabilities
    pub async fn fetch_manifest(&self, addon_base: &str) -> Result<Manifest, String> {
        let base = addon_base.trim_end_matches("/manifest.json").trim_end_matches('/');
        let url = format!("{}/manifest.json", base);
        let resp = self
            .client
            .get(&url)
            .send()
            .await
            .map_err(|e| format!("Failed to request manifest: {}", e))?;

        if !resp.status().is_success() {
            return Err(format!("Manifest returned status: {}", resp.status()));
        }

        resp.json::<Manifest>()
            .await
            .map_err(|e| format!("Failed to parse manifest: {}", e))
    }

    /// Fetch catalog items from any Stremio Addon (including custom Torrent Stream backend)
    pub async fn fetch_catalog(
        &self,
        addon_base: &str,
        catalog_type: &str,
        catalog_id: &str,
        search_query: Option<&str>,
    ) -> Result<CatalogResponse, String> {
        let base = addon_base.trim_end_matches("/manifest.json").trim_end_matches('/');
        let url = if let Some(query) = search_query {
            if !query.trim().is_empty() {
                let encoded = urlencoding::encode(query.trim());
                format!("{}/catalog/{}/{}/search={}.json", base, catalog_type, catalog_id, encoded)
            } else {
                format!("{}/catalog/{}/{}.json", base, catalog_type, catalog_id)
            }
        } else {
            format!("{}/catalog/{}/{}.json", base, catalog_type, catalog_id)
        };

        let resp = self
            .client
            .get(&url)
            .send()
            .await
            .map_err(|e| format!("Failed to fetch catalog from {}: {}", url, e))?;

        if !resp.status().is_success() {
            return Err(format!("Catalog request returned status: {}", resp.status()));
        }

        resp.json::<CatalogResponse>()
            .await
            .map_err(|e| format!("Failed to parse catalog JSON: {}", e))
    }

    /// Cinemeta catalog search fallback
    pub async fn search(&self, query: &str, item_type: &str) -> Result<CatalogResponse, String> {
        let encoded_query = urlencoding::encode(query);
        let url = format!(
            "{}/catalog/{}/top/search={}.json",
            self.cinemeta_url, item_type, encoded_query
        );

        let resp = self
            .client
            .get(&url)
            .send()
            .await
            .map_err(|e| format!("Failed to search Cinemeta: {}", e))?;

        if !resp.status().is_success() {
            return Err(format!("Search failed with status: {}", resp.status()));
        }

        resp.json::<CatalogResponse>()
            .await
            .map_err(|e| format!("Failed to parse catalog: {}", e))
    }

    /// Fetch metadata details
    pub async fn get_meta(&self, item_type: &str, id: &str) -> Result<MetaResponse, String> {
        let url = format!("{}/meta/{}/{}.json", self.cinemeta_url, item_type, id);
        let resp = self
            .client
            .get(&url)
            .send()
            .await
            .map_err(|e| format!("Failed to get meta: {}", e))?;

        resp.json::<MetaResponse>()
            .await
            .map_err(|e| format!("Failed to parse meta: {}", e))
    }

    /// Resolve streams from any Stremio Addon (e.g. your custom backend or Torrentio)
    pub async fn resolve_streams(
        &self,
        addon_base: &str,
        item_type: &str,
        id: &str,
    ) -> Result<StreamResponse, String> {
        let base = addon_base.trim_end_matches("/manifest.json").trim_end_matches('/');
        let url = format!("{}/stream/{}/{}.json", base, item_type, id);

        let resp = self
            .client
            .get(&url)
            .send()
            .await
            .map_err(|e| format!("Failed to resolve streams from {}: {}", url, e))?;

        if !resp.status().is_success() {
            return Err(format!("Stream endpoint returned status: {}", resp.status()));
        }

        resp.json::<StreamResponse>()
            .await
            .map_err(|e| format!("Failed to parse stream JSON: {}", e))
    }
}
