# MongoDB Atlas Setup for DevSpace

1. https://cloud.mongodb.com -> Create Project -> Atlas free tier.
2. Create Cluster.
3. Database access -> Create a user.
4. Network access -> IP whitelist 0.0.0.0/0 (dev only).
5. Databases -> Create `devspace` with collections `users`, `posts`, `notifications`.
6. Get connection string from “Connect -> Connect your application”.

Example URIs:
`mongodb+srv://<user>:<pass>@cluster0.abcde.mongodb.net/devspace?retryWrites=true&w=majority`