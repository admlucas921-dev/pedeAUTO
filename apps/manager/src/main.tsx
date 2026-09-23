import React, { useEffect, useState } from 'react';
import { createRoot } from 'react-dom/client';
import { createClient, type Session } from '@supabase/supabase-js';
import { ArrowRight, LockKeyhole, Mail, Store, LogOut } from 'lucide-react';
import './style.css';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseKey = import.meta.env.VITE_SUPABASE_ANON_KEY;
const supabase = supabaseUrl && supabaseKey ? createClient(supabaseUrl, supabaseKey) : null;
type Mode = 'login'|'register'|'recover'|'reset';

function App(){
 const [session,setSession]=useState<Session|null>(null);
 const [checking,setChecking]=useState(true);
 const [mode,setMode]=useState<Mode>('login');
 const [email,setEmail]=useState('');
 const [password,setPassword]=useState('');
 const [busy,setBusy]=useState(false);
 const [error,setError]=useState('');
 const [notice,setNotice]=useState('');
 useEffect(()=>{if(!supabase){setChecking(false);return}supabase.auth.getSession().then(({data})=>{setSession(data.session);setChecking(false)});const {data:{subscription}}=supabase.auth.onAuthStateChange((event,next)=>{setSession(next);if(event==='PASSWORD_RECOVERY')setMode('reset')});return()=>subscription.unsubscribe()},[]);
 function switchMode(next:Mode){setMode(next);setError('');setNotice('')}
 async function submit(e:React.FormEvent){e.preventDefault();setBusy(true);setError('');setNotice('');try{
  if(!supabase)throw new Error('Configure VITE_SUPABASE_URL e VITE_SUPABASE_ANON_KEY no ambiente do painel.');
  if(mode==='reset'){
   const {error}=await supabase.auth.updateUser({password});if(error)throw error;
   setNotice('Senha atualizada. Você já pode acessar seu painel.');setMode('login');
  } else if(mode==='recover'){
   const {error}=await supabase.auth.resetPasswordForEmail(email,{redirectTo:location.origin});if(error)throw error;
   setNotice('Se este e-mail estiver cadastrado, você receberá as instruções de recuperação.');
  } else if(mode==='register'){
   const {data,error}=await supabase.auth.signUp({email,password,options:{emailRedirectTo:location.origin}});if(error)throw error;
   if(!data.session)setNotice('Cadastro recebido. Confira seu e-mail para confirmar a conta.');
  } else {
   const {error}=await supabase.auth.signInWithPassword({email,password});if(error)throw error;
  }
 }catch(err){setError(err instanceof Error?err.message:'Não foi possível concluir. Tente novamente.')}finally{setBusy(false)}}
 if(checking)return <main className="loading">Carregando…</main>;
 if(session&&mode!=='reset')return <main className="dashboard"><header><span className="brand"><Store size={25}/> pede<span>AUTO</span></span><button onClick={()=>supabase?.auth.signOut()}><LogOut size={18}/> Sair</button></header><section className="welcome"><span className="pill">ÁREA DO GERENTE</span><h1>Bem-vindo ao seu painel.</h1><p>Você entrou como <strong>{session.user.email}</strong>.</p><div className="next"><Store size={28}/><div><h2>Seu cardápio começa aqui</h2><p>O login está funcionando. As configurações do estabelecimento serão exibidas neste painel.</p></div></div></section></main>;
 return <main className="shell"><section className="feature"><div className="feature-inner"><span className="brand light"><Store size={27}/> pede<span>AUTO</span></span><div><span className="eyebrow">GESTÃO DO SEU CARDÁPIO</span><h1>Seu negócio<br/>na palma<br/>da mão.</h1><p>Organize seus produtos, cuide da sua marca e ofereça uma experiência melhor em cada mesa.</p></div><small>Uma experiência simples para quem vende e para quem escolhe.</small></div></section><section className="auth"><div className="auth-inner"><div className="icon"><LockKeyhole size={24}/></div><span className="eyebrow dark">ACESSO AO PAINEL</span><h2>{mode==='login'?'Bem-vindo de volta':mode==='register'?'Crie sua conta':mode==='reset'?'Nova senha':'Recuperar senha'}</h2><p className="intro">{mode==='login'?'Entre para administrar seu cardápio.':mode==='register'?'Comece com seu e-mail e uma senha segura.':mode==='reset'?'Escolha uma nova senha para sua conta.':'Enviaremos um link para seu e-mail.'}</p><form onSubmit={submit}>{mode!=='reset'&&<><label htmlFor="email">E-mail</label><div className="input"><Mail size={19}/><input id="email" type="email" autoComplete="email" placeholder="voce@estabelecimento.com" required value={email} onChange={e=>setEmail(e.target.value)}/></div></>}{mode!=='recover'&&<><label htmlFor="password">Senha</label><div className="input"><LockKeyhole size={19}/><input id="password" type="password" autoComplete={mode==='login'?'current-password':'new-password'} placeholder="Sua senha" minLength={6} required value={password} onChange={e=>setPassword(e.target.value)}/></div></>}{error&&<p role="alert" className="alert">{error}</p>}{notice&&<p role="status" className="success">{notice}</p>}<button className="primary" disabled={busy}>{busy?'Aguarde…':mode==='login'?'Entrar':mode==='register'?'Criar conta':mode==='reset'?'Salvar nova senha':'Enviar link'}<ArrowRight size={19}/></button></form><div className="actions">{mode==='login'?<><button onClick={()=>switchMode('recover')}>Esqueci minha senha</button><p>Ainda não tem conta? <button onClick={()=>switchMode('register')}>Criar conta</button></p></>:<button onClick={()=>switchMode('login')}>Voltar para o login</button>}</div></div></section></main>
}
createRoot(document.getElementById('root')!).render(<App/>);
