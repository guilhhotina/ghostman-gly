# usa o nginx alpine que pesa menos que uma foto de gatinho
FROM nginx:alpine

# copia a config padrão do nginx (bom pra garantir)
COPY nginx.conf /etc/nginx/conf.d/default.conf

# copia o jogo compilado pra pasta pública do servidor
COPY dist/web /usr/share/nginx/html

# expõe a porta 80
EXPOSE 80

# roda o servidor
CMD ["nginx", "-g", "daemon off;"]
