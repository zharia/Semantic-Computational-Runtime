#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum ProcessStatus {
    Pending,
    Running,
    Suspended,
    Completed,
    Failed,
    Cancelled,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ProcessStep {
    pub step_index: usize,
    pub name: String,
    pub completed: bool,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ApplicationProcess {
    pub id: String,
    pub name: String,
    pub status: ProcessStatus,
    pub steps: Vec<ProcessStep>,
    pub current_step: usize,
}

impl ApplicationProcess {
    pub fn new(id: impl Into<String>, name: impl Into<String>) -> Self {
        Self {
            id: id.into(),
            name: name.into(),
            status: ProcessStatus::Pending,
            steps: Vec::new(),
            current_step: 0,
        }
    }

    pub fn add_step(&mut self, step_name: impl Into<String>) {
        let step_index = self.steps.len();
        self.steps.push(ProcessStep {
            step_index,
            name: step_name.into(),
            completed: false,
        });
    }

    pub fn start(&mut self) {
        self.status = ProcessStatus::Running;
    }

    pub fn advance_step(&mut self) -> bool {
        if self.current_step < self.steps.len() {
            self.steps[self.current_step].completed = true;
            self.current_step += 1;
            if self.current_step >= self.steps.len() {
                self.status = ProcessStatus::Completed;
            }
            true
        } else {
            false
        }
    }
}
