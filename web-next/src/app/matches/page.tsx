"use client";

import { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Send, ArrowLeft, Bot } from 'lucide-react';

const MOCK_MATCHES = [
  { id: 1, name: "Neon Alpha", avatar: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&q=60", lastMsg: "Hey, are you ready for the quest?" },
  { id: 2, name: "Cyber Queen", avatar: "https://images.unsplash.com/photo-1517841905240-472988babdf9?w=100&q=60", lastMsg: "System breached." },
  { id: 3, name: "Glitch", avatar: "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=100&q=60", lastMsg: "Error 404: Love not found." }
];

export default function MatchesPage() {
  const [activeChat, setActiveChat] = useState<number | null>(null);
  const [messages, setMessages] = useState<{role: string, content: string}[]>([
    { role: 'assistant', content: "Hey there! Ready to start the SparkQuest?" }
  ]);
  const [input, setInput] = useState("");
  const [isTyping, setIsTyping] = useState(false);

  const sendMessage = async () => {
    if (!input.trim()) return;
    
    const newMsgs = [...messages, { role: 'user', content: input }];
    setMessages(newMsgs);
    setInput("");
    setIsTyping(true);

    try {
      const res = await fetch('/api/groq', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ messages: newMsgs })
      });
      const data = await res.json();
      
      if (data.choices && data.choices[0]) {
        setMessages([...newMsgs, data.choices[0].message]);
      }
    } catch (err) {
      console.error(err);
      setMessages([...newMsgs, { role: 'assistant', content: "[System Error: Connection Lost]" }]);
    }
    setIsTyping(false);
  };

  const activeBot = MOCK_MATCHES.find(m => m.id === activeChat);

  return (
    <div className="flex flex-col h-full w-full bg-dark overflow-hidden relative">
      <AnimatePresence>
        {!activeChat ? (
          <motion.div 
            initial={{ opacity: 0, x: -50 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -50 }}
            className="w-full h-full p-6 pt-12 overflow-y-auto"
          >
            <h1 className="text-3xl font-black text-primary mb-8 drop-shadow-[0_0_15px_rgba(255,0,128,0.8)] tracking-tight">MATCHES</h1>
            
            <div className="flex overflow-x-auto gap-4 pb-4 mb-4 hide-scrollbar">
              {MOCK_MATCHES.map((bot) => (
                <div key={bot.id} className="flex flex-col items-center gap-2 min-w-[80px]">
                  <div className="w-16 h-16 rounded-full bg-zinc-800 border-2 border-primary shadow-[0_0_10px_rgba(255,0,128,0.4)] relative overflow-hidden">
                    <img src={bot.avatar} className="w-full h-full object-cover" />
                    <div className="absolute -bottom-1 -right-1 w-4 h-4 bg-green-500 rounded-full border-2 border-black"></div>
                  </div>
                  <span className="text-[10px] text-white/80 font-bold uppercase tracking-wider">{bot.name.split(' ')[0]}</span>
                </div>
              ))}
            </div>

            <div className="flex flex-col gap-3">
              {MOCK_MATCHES.map((bot) => (
                <div 
                  key={bot.id} 
                  onClick={() => setActiveChat(bot.id)}
                  className="w-full bg-[#1a1a1a] rounded-3xl p-4 border border-white/5 flex items-center gap-4 hover:bg-[#222] transition-colors cursor-pointer shadow-lg"
                >
                  <div className="w-14 h-14 rounded-full bg-zinc-800 flex-shrink-0 overflow-hidden relative">
                    <img src={bot.avatar} className="w-full h-full object-cover" />
                    <div className="absolute inset-0 bg-primary/20 mix-blend-overlay"></div>
                  </div>
                  <div className="flex-1">
                    <h3 className="font-bold text-white tracking-wide">{bot.name}</h3>
                    <p className="text-sm text-white/50 line-clamp-1">{bot.lastMsg}</p>
                  </div>
                  <div className="text-xs text-white/30 font-bold">2m</div>
                </div>
              ))}
            </div>
          </motion.div>
        ) : (
          <motion.div 
            initial={{ opacity: 0, x: 50 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: 50 }}
            className="absolute inset-0 z-40 bg-zinc-950 flex flex-col h-full"
          >
            {/* Chat Header */}
            <div className="h-[80px] bg-black/80 backdrop-blur-xl border-b border-white/5 flex items-center px-4 gap-4 z-50">
              <button onClick={() => setActiveChat(null)} className="p-2 bg-white/5 rounded-full hover:bg-white/10 transition-colors">
                <ArrowLeft className="w-6 h-6 text-white" />
              </button>
              <div className="w-10 h-10 rounded-full bg-zinc-800 overflow-hidden border border-primary">
                <img src={activeBot?.avatar} className="w-full h-full object-cover" />
              </div>
              <div>
                <h2 className="font-bold text-white tracking-wide">{activeBot?.name}</h2>
                <p className="text-[10px] text-green-400 font-bold tracking-widest flex items-center gap-1">
                  <span className="w-1.5 h-1.5 rounded-full bg-green-500 animate-pulse"></span> ONLINE (AI)
                </p>
              </div>
            </div>

            {/* Chat History */}
            <div className="flex-1 overflow-y-auto p-4 flex flex-col gap-4 pb-20">
              {messages.map((msg, i) => (
                <div key={i} className={`flex ${msg.role === 'user' ? 'justify-end' : 'justify-start'}`}>
                  <div className={`max-w-[75%] p-4 rounded-3xl text-sm leading-relaxed ${
                    msg.role === 'user' 
                    ? 'bg-gradient-to-br from-primary to-accent text-white rounded-tr-sm shadow-[0_5px_15px_rgba(255,0,128,0.2)]' 
                    : 'bg-[#222] border border-white/5 text-white/90 rounded-tl-sm shadow-lg'
                  }`}>
                    {msg.content}
                  </div>
                </div>
              ))}
              {isTyping && (
                <div className="flex justify-start">
                  <div className="bg-[#222] border border-white/5 text-white/50 p-4 rounded-3xl rounded-tl-sm flex items-center gap-2">
                    <Bot className="w-4 h-4 animate-bounce" /> Processing...
                  </div>
                </div>
              )}
            </div>

            {/* Chat Input */}
            <div className="absolute bottom-0 w-full p-4 bg-gradient-to-t from-black to-transparent">
              <div className="flex gap-2 bg-[#1a1a1a] p-2 rounded-full border border-white/10 shadow-2xl backdrop-blur-md">
                <input 
                  type="text" 
                  value={input}
                  onChange={e => setInput(e.target.value)}
                  onKeyDown={e => e.key === 'Enter' && sendMessage()}
                  placeholder="Send a message..." 
                  className="flex-1 bg-transparent text-white px-4 py-2 outline-none text-sm placeholder-white/30"
                />
                <button 
                  onClick={sendMessage}
                  disabled={!input.trim() || isTyping}
                  className="w-10 h-10 rounded-full bg-primary flex items-center justify-center text-white hover:bg-accent transition-colors shadow-[0_0_10px_rgba(255,0,128,0.5)] disabled:opacity-50"
                >
                  <Send className="w-4 h-4" />
                </button>
              </div>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}
