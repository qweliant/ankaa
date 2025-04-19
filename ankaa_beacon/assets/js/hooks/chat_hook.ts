interface ChatHook {
  mounted(): void;
  updated(): void;
  scrollToBottom(): void;
}

const ChatHook: ChatHook = {
  mounted() {
    this.scrollToBottom();
  },

  updated() {
    this.scrollToBottom();
  },

  scrollToBottom() {
    const messagesContainer = document.getElementById("chat-messages");
    if (messagesContainer) {
      messagesContainer.scrollTop = messagesContainer.scrollHeight;
    }
  },
};

export default ChatHook;
