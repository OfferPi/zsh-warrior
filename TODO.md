# Plugin To-Do List

A checklist of improvements and features to add.

- [ ] **Improve logging** for the entire plugin
  Make sure all code logs, not  only the `llm_wrapper.py` script.

- [ ] **Check dependencies before loading**  
  Detect missing dependencies.  
  Show clear error messages if requirements aren’t met.

- [ ] **Update README** with explanation and install instructions  
  Describe plugin purpose.  
  Provide step-by-step setup guide.  
  Include examples of usage.

- [ ] **Add “keep alive” to Ollama** in the `llm_wrapper.py` script  
  Prevent Ollama from timing out.  

- [ ] **Add a “super mode”** that uses a different model and context  
  Allow switching to a higher-capacity model.  
  Provide extra context to the model in this mode.

- [ ] **Include environment information** in the LLM prompt  
  Inject details about the system into prompts for better responses.
  Inject default editor.
  Inject OS Version.
  Inject Packet manager.
  Maybe inject available commands.

