use crate::adapter::ApplicationAdapter;
use crate::controller::ApplicationController;
use crate::port::ApplicationPort;
use crate::service::ApplicationService;
use std::collections::BTreeMap;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ApplicationModule {
    pub id: String,
    pub name: String,
    pub description: String,
    pub submodules: Vec<String>,
    pub services: BTreeMap<String, ApplicationService>,
    pub controllers: BTreeMap<String, ApplicationController>,
    pub ports: BTreeMap<String, ApplicationPort>,
    pub adapters: BTreeMap<String, ApplicationAdapter>,
}

impl ApplicationModule {
    pub fn new(id: impl Into<String>, name: impl Into<String>) -> Self {
        Self {
            id: id.into(),
            name: name.into(),
            description: String::new(),
            submodules: Vec::new(),
            services: BTreeMap::new(),
            controllers: BTreeMap::new(),
            ports: BTreeMap::new(),
            adapters: BTreeMap::new(),
        }
    }

    pub fn register_service(&mut self, srv: ApplicationService) {
        self.services.insert(srv.id.clone(), srv);
    }

    pub fn register_controller(&mut self, ctrl: ApplicationController) {
        self.controllers.insert(ctrl.id.clone(), ctrl);
    }

    pub fn register_port(&mut self, port: ApplicationPort) {
        self.ports.insert(port.id.clone(), port);
    }

    pub fn register_adapter(&mut self, adapter: ApplicationAdapter) {
        self.adapters.insert(adapter.id.clone(), adapter);
    }
}
