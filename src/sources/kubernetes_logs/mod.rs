//! This mod implements `kubernetes_logs` source.
//! The scope of this source is to consume the log files that `kubelet` keeps
//! at `/var/logs/pods` at the host of the k8s node.

#![deny(missing_docs)]

use crate::{
    event::Event,
    shutdown::ShutdownSignal,
    sources,
    topology::config::{DataType, GlobalOptions, SourceConfig, SourceDescription},
};
use futures01::sync::mpsc;
use serde::{Deserialize, Serialize};

// # TODO List
//
// - Read files.
//   - JsonLines format.
//   - CRI format.
//   - Automatic partial merge.
// - Namespace.

const COMPONENT_NAME: &str = "kubernetes_logs";

#[derive(Deserialize, Serialize, Debug, Clone)]
pub struct Config {}

inventory::submit! {
    SourceDescription::new_without_default::<Config>(COMPONENT_NAME)
}

#[derive(Clone)]
struct Source {}

#[typetag::serde(name = "kubernetes_logs")]
impl SourceConfig for Config {
    fn build(
        &self,
        name: &str,
        globals: &GlobalOptions,
        shutdown: ShutdownSignal,
        out: mpsc::Sender<Event>,
    ) -> crate::Result<sources::Source> {
        let fut = source();
        let fut = futures::compat::Compat::new(fut);
        let fut = Box::new(fut);
        Ok(fut)
    }

    fn output_type(&self) -> DataType {
        DataType::Log
    }

    fn source_type(&self) -> &'static str {
        COMPONENT_NAME
    }
}


async fn source() {}
