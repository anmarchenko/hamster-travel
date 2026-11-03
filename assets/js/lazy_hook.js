// Keep the LiveView hook instance (and its pushEvent/handleEvent API) intact.
// Imports are cached by the browser; each mounted element gets its own delegate.
export function lazyHook(load, name) {
  const stateKey = Symbol(name);
  const callbacks = ['beforeUpdate', 'updated', 'disconnected', 'reconnected'];
  const hook = {
    mounted() {
      const state = { destroyed: false, delegate: null, connected: true };
      this[stateKey] = state;

      return load().then((module) => {
        if (state.destroyed) return;

        const delegate = module.default[name];
        for (const [key, value] of Object.entries(delegate)) {
          if (key !== 'mounted' && key !== 'destroyed' && !callbacks.includes(key)) {
            this[key] = value;
          }
        }
        state.delegate = delegate;
        delegate.mounted?.call(this);
        if (!state.connected) delegate.disconnected?.call(this);
      }).catch((error) => {
        // A failed optional feature must not prevent the socket from connecting.
        if (!state.destroyed) console.error(`Unable to load ${name}`, error);
      });
    },

    destroyed() {
      const state = this[stateKey];
      state.destroyed = true;
      state.delegate?.destroyed?.call(this);
    },
  };

  for (const callback of callbacks) {
    hook[callback] = function () {
      const state = this[stateKey];
      if (callback === 'disconnected') state.connected = false;
      if (callback === 'reconnected') state.connected = true;
      if (!state.destroyed) state.delegate?.[callback]?.call(this);
    };
  }

  return hook;
}
